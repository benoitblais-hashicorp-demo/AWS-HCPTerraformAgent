<!-- BEGIN_TF_DOCS -->
# HCP Terraform Agent Host on AWS

## What this demo demonstrates

This demo provisions a secure AWS environment to run HCP Terraform agents on a single private EC2 host. It automates the full host baseline and the agent runtime setup, including HCP Terraform agent pool creation, token generation, secret storage, and systemd service startup for each agent.

## Features

- Private VPC topology with public and private subnets across multiple Availability Zones.
- NAT-based outbound connectivity for private workloads.
- One dedicated Linux EC2 host for HCP Terraform agents.
- Configurable number of agents (default: 5, max: 5).
- Automated HCP Terraform agent pool and per-agent token creation.
- Secure token storage in AWS Secrets Manager.
- Bootstrap script that installs tfc-agent and configures one systemd service per agent.
- IAM least privilege for token retrieval and SSM-based host management.

## Demo Components

- AWS networking: VPC, subnets, routes, Internet Gateway, NAT Gateway.
- Security controls: security group rules with optional CIDR-restricted SSH.
- Compute: private EC2 instance with encrypted storage and IMDSv2 required.
- IAM: instance role, instance profile, and token-reader policy.
- HCP Terraform: `tfe_agent_pool` and `tfe_agent_token` resources.
- Secrets: one AWS Secrets Manager secret per agent token.
- Runtime automation: cloud-init/user\_data template with systemd unit creation.

## How this demo works

1. Terraform provisions AWS networking and one private EC2 host.
2. Terraform creates an HCP Terraform agent pool and one token per configured agent.
3. Terraform writes each token into AWS Secrets Manager under a structured path.
4. EC2 user data installs tfc-agent and supporting packages.
5. A startup script fetches each token at runtime and launches dedicated systemd services.

## Demo Value Proposition

- Shows a production-oriented pattern for running multiple HCP Terraform agents on AWS.
- Reduces operational risk by keeping tokens out of Terraform outputs and source files.
- Demonstrates secure-by-default controls: private host placement, IMDSv2, least-privilege IAM, and SSM-first administration.
- Provides a reusable baseline that can be adapted to enterprise networking and policy requirements.

## How to Conduct the Demo

1. Configure required variables (`tfe_organization`).
2. Confirm HCP Terraform workspace authentication is configured for AWS Dynamic Provider Credentials.
3. Set the HCP Terraform API token as an environment variable (`TFE_TOKEN`) in the execution environment.
4. Run `terraform init`, `terraform plan`, and `terraform apply`.
5. Validate outputs (instance details, pool id, and token secret identifiers).
6. Connect through SSM Session Manager and verify running `tfc-agent-*` services.

## Expected Behavior

- Terraform creates exactly one private EC2 host for agents.
- The default deployment starts 5 agent services (`tfc-agent-1` to `tfc-agent-5`).
- No plaintext HCP Terraform token appears in Terraform output.
- Agent services can reach required HCP Terraform endpoints over outbound HTTPS.

## Permissions

### AWS Permissions

To provision the AWS resources managed by this code, the IAM role or user running Terraform needs permissions such as:

- `ec2:DescribeAvailabilityZones`
- `ec2:DescribeImages`
- `ec2:DescribeVpcs`
- `ec2:CreateVpc`
- `ec2:DeleteVpc`
- `ec2:CreateSubnet`
- `ec2:DeleteSubnet`
- `ec2:CreateRouteTable`
- `ec2:DeleteRouteTable`
- `ec2:CreateRoute`
- `ec2:ReplaceRoute`
- `ec2:DeleteRoute`
- `ec2:AssociateRouteTable`
- `ec2:DisassociateRouteTable`
- `ec2:CreateInternetGateway`
- `ec2:AttachInternetGateway`
- `ec2:DetachInternetGateway`
- `ec2:DeleteInternetGateway`
- `ec2:AllocateAddress`
- `ec2:ReleaseAddress`
- `ec2:CreateNatGateway`
- `ec2:DeleteNatGateway`
- `ec2:CreateSecurityGroup`
- `ec2:DeleteSecurityGroup`
- `ec2:AuthorizeSecurityGroupIngress`
- `ec2:RevokeSecurityGroupIngress`
- `ec2:AuthorizeSecurityGroupEgress`
- `ec2:RevokeSecurityGroupEgress`
- `ec2:RunInstances`
- `ec2:TerminateInstances`
- `ec2:DescribeInstances`
- `ec2:CreateTags`
- `ec2:DeleteTags`
- `iam:CreateRole`
- `iam:DeleteRole`
- `iam:GetRole`
- `iam:PassRole`
- `iam:CreatePolicy`
- `iam:DeletePolicy`
- `iam:GetPolicy`
- `iam:GetPolicyVersion`
- `iam:CreateInstanceProfile`
- `iam:DeleteInstanceProfile`
- `iam:GetInstanceProfile`
- `iam:AddRoleToInstanceProfile`
- `iam:RemoveRoleFromInstanceProfile`
- `iam:AttachRolePolicy`
- `iam:DetachRolePolicy`
- `secretsmanager:CreateSecret`
- `secretsmanager:DeleteSecret`
- `secretsmanager:DescribeSecret`
- `secretsmanager:PutSecretValue`
- `secretsmanager:UpdateSecret`
- `secretsmanager:TagResource`
- `secretsmanager:UntagResource`

The EC2 instance profile used at runtime requires:

- `secretsmanager:GetSecretValue`
- `secretsmanager:DescribeSecret`
- `AmazonSSMManagedInstanceCore` managed policy for SSM administration.

### HCP Terraform Permissions

To manage the resources from this code, provide a token from an account with `Manage agent pools` and `View all workspaces` permissions. Alternatively, you can use a token from a team instead of a user token.

## Authentications

### AWS Authentication

AWS authentication is expected to use HCP Terraform Dynamic Provider Credentials (OIDC role assumption).

- Configure the HCP Terraform workspace to assume an AWS IAM role.
- Do not use long-lived static AWS credentials for normal runs.

### HCP Terraform Authentication

The TFE provider authenticates with the `TFE_TOKEN` environment variable.

```bash
export TFE_TOKEN="<hcp_terraform_user_or_team_token>"
```

Optional (when using a non-default hostname):

```bash
export TFE_HOSTNAME="app.terraform.io"
```

## Documentation

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.7.0)

- <a name="requirement_aws"></a> [aws](#requirement\_aws) (~> 5.79)

- <a name="requirement_tfe"></a> [tfe](#requirement\_tfe) (~> 0.66)

## Modules

The following Modules are called:

### <a name="module_agent_host_sg"></a> [agent\_host\_sg](#module\_agent\_host\_sg)

Source: app.terraform.io/benoitblais-hashicorp/security-group/aws

Version: 0.0.2

### <a name="module_vpc"></a> [vpc](#module\_vpc)

Source: app.terraform.io/benoitblais-hashicorp/vpc/aws

Version: 0.0.1

## Required Inputs

The following input variables are required:

### <a name="input_tfe_organization"></a> [tfe\_organization](#input\_tfe\_organization)

Description: (Required) HCP Terraform organization where the agent pool and tokens are created.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_agent_count"></a> [agent\_count](#input\_agent\_count)

Description: (Optional) Number of HCP Terraform agents to run on the EC2 host and number of tokens to create.

Type: `number`

Default: `5`

### <a name="input_agent_host_ami_id"></a> [agent\_host\_ami\_id](#input\_agent\_host\_ami\_id)

Description: (Optional) Custom AMI ID for the EC2 host. If empty, Ubuntu Pro LTS AMI discovery is used.

Type: `string`

Default: `""`

### <a name="input_agent_host_instance_type"></a> [agent\_host\_instance\_type](#input\_agent\_host\_instance\_type)

Description: (Optional) EC2 instance type for the host running up to 5 HCP Terraform agents.

Type: `string`

Default: `"t3.large"`

### <a name="input_agent_host_root_volume_size_gb"></a> [agent\_host\_root\_volume\_size\_gb](#input\_agent\_host\_root\_volume\_size\_gb)

Description: (Optional) Root disk size in GiB for the EC2 host.

Type: `number`

Default: `64`

### <a name="input_availability_zone_count"></a> [availability\_zone\_count](#input\_availability\_zone\_count)

Description: (Optional) Number of availability zones used for public/private subnets.

Type: `number`

Default: `2`

### <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region)

Description: (Optional) AWS region for infrastructure deployment.

Type: `string`

Default: `"ca-central-1"`

### <a name="input_environment"></a> [environment](#input\_environment)

Description: (Optional) Environment tag value.

Type: `string`

Default: `"demo"`

### <a name="input_management_cidrs"></a> [management\_cidrs](#input\_management\_cidrs)

Description: (Optional) CIDR block(s) allowed for SSH management. Accepts a single CIDR string or a list of CIDRs. Leave empty to disable SSH ingress.

Type: `any`

Default: `[]`

### <a name="input_project_name"></a> [project\_name](#input\_project\_name)

Description: (Optional) Project name used in resource naming and tagging.

Type: `string`

Default: `"hcp-terraform-agent-host"`

### <a name="input_tfc_agent_run_user"></a> [tfc\_agent\_run\_user](#input\_tfc\_agent\_run\_user)

Description: (Optional) Linux user that runs the tfc-agent services.

Type: `string`

Default: `"terraform-agent"`

### <a name="input_tfc_agent_token_secret_prefix"></a> [tfc\_agent\_token\_secret\_prefix](#input\_tfc\_agent\_token\_secret\_prefix)

Description: (Optional) AWS Secrets Manager prefix where agent tokens are stored.

Type: `string`

Default: `"/hcp-tf-agent"`

### <a name="input_tfc_agent_version"></a> [tfc\_agent\_version](#input\_tfc\_agent\_version)

Description: (Optional) HCP Terraform agent version to install on the EC2 host. Set to latest to resolve at runtime.

Type: `string`

Default: `"latest"`

### <a name="input_tfe_agent_pool_name"></a> [tfe\_agent\_pool\_name](#input\_tfe\_agent\_pool\_name)

Description: (Optional) Name of the HCP Terraform agent pool.

Type: `string`

Default: `"aws"`

### <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr)

Description: (Optional) CIDR block for the VPC.

Type: `string`

Default: `"10.42.0.0/16"`

## Resources

The following resources are used by this module:

- [aws_iam_instance_profile.agent_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) (resource)
- [aws_iam_policy.agent_token_reader](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) (resource)
- [aws_iam_role.agent_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) (resource)
- [aws_iam_role_policy_attachment.agent_token_reader](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) (resource)
- [aws_iam_role_policy_attachment.ssm_core](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) (resource)
- [aws_instance.agent_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) (resource)
- [aws_secretsmanager_secret.agent_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) (resource)
- [aws_secretsmanager_secret_version.agent_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) (resource)
- [tfe_agent_pool.main](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/agent_pool) (resource)
- [tfe_agent_token.agent](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/agent_token) (resource)
- [aws_ami.ubuntu_pro](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) (data source)
- [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) (data source)

## Outputs

The following outputs are exported:

### <a name="output_agent_host_ami_id"></a> [agent\_host\_ami\_id](#output\_agent\_host\_ami\_id)

Description: AMI ID used by the EC2 host instance

### <a name="output_agent_host_id"></a> [agent\_host\_id](#output\_agent\_host\_id)

Description: EC2 instance ID for the HCP Terraform agent host

### <a name="output_agent_host_private_ip"></a> [agent\_host\_private\_ip](#output\_agent\_host\_private\_ip)

Description: Private IP address of the HCP Terraform agent host

### <a name="output_agent_host_security_group_id"></a> [agent\_host\_security\_group\_id](#output\_agent\_host\_security\_group\_id)

Description: Security group ID attached to the HCP Terraform agent host

### <a name="output_agent_pool_id"></a> [agent\_pool\_id](#output\_agent\_pool\_id)

Description: HCP Terraform agent pool ID

### <a name="output_agent_token_secret_arns"></a> [agent\_token\_secret\_arns](#output\_agent\_token\_secret\_arns)

Description: AWS Secrets Manager ARNs storing HCP Terraform agent tokens

### <a name="output_agent_token_secret_ids"></a> [agent\_token\_secret\_ids](#output\_agent\_token\_secret\_ids)

Description: AWS Secrets Manager secret identifiers used by the startup script

### <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids)

Description: Private subnet IDs where private workloads can run

### <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids)

Description: Public subnet IDs used for ingress and NAT infrastructure

### <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id)

Description: VPC ID created for the HCP Terraform agent infrastructure

<!-- markdownlint-enable -->
<!-- END_TF_DOCS -->