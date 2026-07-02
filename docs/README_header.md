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
- Runtime automation: cloud-init/user_data template with systemd unit creation.

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
7. Demonstrate token revocation by revoking one agent token in HCP Terraform, then show that the compromised token can no longer register/connect.

## Agent Operations Reference

To see the status of the agents in case of troubleshooting, use the following commands.

### Check agent status (example with 3 agents)

```bash
sudo systemctl status tfc-agent-1
sudo systemctl status tfc-agent-2
sudo systemctl status tfc-agent-3
```

## Security Demo: Revoke a Compromised Token

1. Identify one agent token in the HCP Terraform agent pool (for example, `agent-3`) and revoke it.
2. On the EC2 host, restart the corresponding service: `sudo systemctl restart tfc-agent-3`.
3. Verify the service logs/status show authentication failure or inability to register.
4. Confirm in HCP Terraform that the revoked token no longer produces a healthy connected agent.
5. Rotate by creating a replacement token and updating the corresponding AWS Secrets Manager secret value.

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
