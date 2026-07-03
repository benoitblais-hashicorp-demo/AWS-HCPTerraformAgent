output "agent_host_ami_id" {
  description = "AMI ID used by the EC2 host instance"
  value       = aws_instance.agent_host.ami
}

output "agent_host_id" {
  description = "EC2 instance ID for the HCP Terraform agent host"
  value       = aws_instance.agent_host.id
}

output "agent_host_private_ip" {
  description = "Private IP address of the HCP Terraform agent host"
  value       = aws_instance.agent_host.private_ip
}

output "agent_host_security_group_id" {
  description = "Security group ID attached to the HCP Terraform agent host"
  value       = module.agent_host_sg.security_group_id
}

output "agent_pool_id" {
  description = "HCP Terraform agent pool ID"
  value       = tfe_agent_pool.main.id
}

output "agent_token_secret_arns" {
  description = "AWS Secrets Manager ARNs storing HCP Terraform agent tokens"
  value = {
    for agent_name, secret in aws_secretsmanager_secret.agent_token :
    agent_name => secret.arn
  }
}

output "agent_token_secret_ids" {
  description = "AWS Secrets Manager secret identifiers used by the startup script"
  value = {
    for agent_name, secret in aws_secretsmanager_secret.agent_token :
    agent_name => secret.name
  }
}

output "private_subnet_ids" {
  description = "Private subnet IDs where private workloads can run"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs used for ingress and NAT infrastructure"
  value       = module.vpc.public_subnets
}

output "vpc_id" {
  description = "VPC ID created for the HCP Terraform agent infrastructure"
  value       = module.vpc.vpc_id
}
