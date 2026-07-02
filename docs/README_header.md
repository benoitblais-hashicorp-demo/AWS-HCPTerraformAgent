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

1. Configure required variables (`tfe_organization`, AWS region, networking, and agent settings).
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

### Required Access by Deployment Phase

The following access is required to deploy this solution end-to-end.

#### Deployment 1: AWS Infrastructure Baseline

This phase provisions VPC, security controls, IAM, EC2, and Secrets Manager containers.

Required AWS API access includes:

- EC2 and networking management for VPC/subnet/routing/NAT/security group/instance operations.
- IAM role, policy, and instance profile management for the EC2 host role.
- Secrets Manager secret and secret version management.
- Read access used by data sources (for example, Availability Zones and AMI discovery).

In practice, this is commonly delivered with:

- A deployment role trusted by HCP Terraform Dynamic Provider Credentials.
- Permission boundaries and SCPs that allow required EC2, IAM, and Secrets Manager actions in the target account.

#### Deployment 2: HCP Terraform Agent Runtime Automation

This phase creates HCP Terraform agent pool and tokens, stores tokens in Secrets Manager, and boots runtime services on EC2.

Required AWS API access includes:

- Secrets Manager write access for storing generated agent tokens.
- EC2 instance configuration support for user data execution and instance profile attachment.

Required HCP Terraform API access includes:

- Agent pool creation and management in the target organization.
- Agent token creation for each configured agent.

### EC2 Runtime Permissions (instance profile)

The EC2 instance role requires only:

- `secretsmanager:GetSecretValue`
- `secretsmanager:DescribeSecret`
- `AmazonSSMManagedInstanceCore` managed policy for SSM administration.

## Authentications

### AWS Provider Authentication

AWS authentication is expected to use HCP Terraform Dynamic Provider Credentials (OIDC role assumption).

- Configure the HCP Terraform workspace to assume an AWS IAM role.
- Do not use long-lived static AWS credentials for normal runs.

### Terraform (TFE) Provider Authentication

The TFE provider authenticates with the `TFE_TOKEN` environment variable.

```bash
export TFE_TOKEN="<hcp_terraform_user_or_team_token>"
```

Optional (when using a non-default hostname):

```bash
export TFE_HOSTNAME="app.terraform.io"
```


