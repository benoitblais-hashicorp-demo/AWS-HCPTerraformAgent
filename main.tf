locals {
  agent_names = [for index in range(var.agent_count) : "agent-${index + 1}"]

  agent_secret_ids = {
    for agent_name in local.agent_names :
    agent_name => "${trimsuffix(var.tfc_agent_token_secret_prefix, "/")}/${agent_name}/token"
  }
}

# ==============================================================================
# Agent Host Infrastructure
# ==============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

# Organization-hardened Ubuntu baseline image.
data "aws_ami" "ubuntu_pro" {
  most_recent = true
  owners      = ["888995627335"] # ami-prod account

  filter {
    name   = "name"
    values = ["hc-base-ubuntu*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

module "vpc" {
  source  = "app.terraform.io/benoitblais-hashicorp/vpc/aws"
  version = "0.0.1"

  name = "hcp-agent-vpc"
  cidr = var.vpc_cidr

  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    var.availability_zone_count
  )

  public_subnets = [
    for index, _az in slice(data.aws_availability_zones.available.names, 0, var.availability_zone_count) :
    cidrsubnet(var.vpc_cidr, 8, index + 1)
  ]

  private_subnets = [
    for index, _az in slice(data.aws_availability_zones.available.names, 0, var.availability_zone_count) :
    cidrsubnet(var.vpc_cidr, 8, index + 10)
  ]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  map_public_ip_on_launch = true
}

module "agent_host_sg" {
  source  = "app.terraform.io/benoitblais-hashicorp/security-group/aws"
  version = "0.0.2"

  name        = "hcp-agent-host-sg"
  description = "Security group for HCP Terraform agent host"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = length(var.management_cidrs) > 0 ? [
    for cidr in var.management_cidrs : {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Optional SSH management access"
      cidr_blocks = cidr
    }
  ] : []

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Outbound HTTPS for Terraform APIs and provider endpoints"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 7146
      to_port     = 7146
      protocol    = "tcp"
      description = "Outbound agent RPC used by advanced HCP Terraform agent features"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      description = "Outbound DNS queries"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      description = "Outbound DNS over TCP"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_iam_role" "agent_host" {
  name = "hcp-agent-host-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.agent_host.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "agent_token_reader" {
  name        = "hcp-agent-token-reader-policy"
  description = "Least-privilege policy allowing EC2 host to read its HCP Terraform agent tokens"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadAgentTokens"
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          for secret in aws_secretsmanager_secret.agent_token :
          secret.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "agent_token_reader" {
  role       = aws_iam_role.agent_host.name
  policy_arn = aws_iam_policy.agent_token_reader.arn
}

resource "aws_iam_instance_profile" "agent_host" {
  name = "hcp-agent-host-instance-profile"
  role = aws_iam_role.agent_host.name
}

# ==============================================================================
# HCP Terraform Agent Runtime
# ==============================================================================

resource "tfe_agent_pool" "main" {
  name         = var.tfe_agent_pool_name
  organization = var.tfe_organization
}

resource "tfe_agent_token" "agent" {
  for_each = local.agent_secret_ids

  description   = "Token for ${each.key} running on the shared EC2 agent host"
  agent_pool_id = tfe_agent_pool.main.id
}

resource "aws_secretsmanager_secret" "agent_token" {
  for_each = local.agent_secret_ids

  name                    = each.value
  description             = "HCP Terraform agent token for ${each.key}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "agent_token" {
  for_each = local.agent_secret_ids

  secret_id     = aws_secretsmanager_secret.agent_token[each.key].id
  secret_string = tfe_agent_token.agent[each.key].token
}

resource "aws_instance" "agent_host" {
  ami = var.agent_host_ami_id != "" ? var.agent_host_ami_id : data.aws_ami.ubuntu_pro.id

  instance_type               = var.agent_host_instance_type
  iam_instance_profile        = aws_iam_instance_profile.agent_host.name
  subnet_id                   = module.vpc.private_subnets[0]
  vpc_security_group_ids      = [module.agent_host_sg.security_group_id]
  associate_public_ip_address = false

  user_data = templatefile("${path.module}/scripts/bootstrap_tfc_agents.sh.tftpl", {
    agent_count                   = var.agent_count
    aws_region                    = var.aws_region
    tfc_agent_run_user            = var.tfc_agent_run_user
    tfc_agent_token_secret_prefix = trimsuffix(var.tfc_agent_token_secret_prefix, "/")
    tfc_agent_version             = var.tfc_agent_version
  })

  root_block_device {
    encrypted   = true
    volume_size = var.agent_host_root_volume_size_gb
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name = "hcp-agent-host-ec2"
    Role = "hcp-terraform-agent-host"
  }

  depends_on = [
    aws_iam_role_policy_attachment.agent_token_reader,
    aws_secretsmanager_secret_version.agent_token
  ]
}
