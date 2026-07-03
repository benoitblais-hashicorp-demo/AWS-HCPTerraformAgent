# AWS HCP Terraform Agent Host Specification

## 1. Purpose

Define the target architecture and implementation requirements for a Terraform-based deployment on AWS that hosts HCP Terraform agents.

This specification is the source of truth for implementation behavior, guardrails, and acceptance criteria.

## 2. Scope

### 2.1 In Scope

- Provision AWS networking with Terraform:
  - VPC and subnets across at least two availability zones
  - Internet Gateway and NAT Gateway for controlled outbound access
- Provision one Linux EC2 host dedicated to HCP Terraform agents.
- Size the host to support a configurable number of HCP Terraform agent processes (default: 5, max: 5).
- Keep the host private (no public IP by default).
- Configure least-privilege network access required for HCP Terraform agent connectivity.
- Configure IAM and SSM Session Manager access for administration.
- Select a secure baseline AMI (Ubuntu Pro preferred, or compatible hardened Linux baseline).
- Automate HCP Terraform agent pool and token creation.
- Store per-agent tokens in AWS Secrets Manager.
- Bootstrap the host to install tfc-agent and create one systemd service per agent.

### 2.2 Out of Scope

- Managing HCP Terraform agent pools through API automation.
- Vault integration, RDS, ALB, and Route53 implementation.
- Application workload deployment on the EC2 host.

## 3. Platform Constraints and External Requirements

- Target platform: AWS + HCP Terraform.
- Infrastructure execution model: HCP Terraform workspace with VCS-driven runs.
- HCP Terraform Agent requirements reference:
  - Linux x86_64 or ARM64 agents are supported.
  - Hosts should have sufficient resources and consistent sizing per pool.
  - Baseline host requirements include at least 2 GB memory and at least 4 GB free disk, with additional capacity based on workload.
  - Outbound connectivity is required for endpoints used by HCP Terraform agents, including HTTPS (443) and agent RPC (7146) use cases.

## 4. Architecture Requirements

### 4.1 Networking

- VPC includes public and private subnets across at least two availability zones.
- NAT-based outbound internet access is provided for private subnets.
- EC2 agent host runs in a private subnet.
- Security group rules follow least privilege:
  - No inbound internet access by default.
  - Optional SSH only when explicitly enabled and CIDR-restricted.
  - Outbound traffic allows required ports for agent operations (HTTPS, DNS, and agent RPC capability).

### 4.2 Compute

- Provision exactly one EC2 instance for agent hosting.
- Default instance size must be appropriate for running up to 5 agents (for example, `t3.large` or equivalent).
- Root volume is encrypted at rest and sized to exceed baseline agent storage requirements.
- EC2 metadata service must require IMDSv2.

### 4.3 Access and Operations

- Use an EC2 IAM role with SSM permissions for secure administration.
- Prefer SSM Session Manager over direct SSH access.
- User data installs tfc-agent and creates systemd services for each configured agent.
- Runtime startup scripts must fetch tokens from AWS Secrets Manager at service start time.
- User data and Terraform source must not contain plaintext agent token values.

### 4.4 Token and Secret Management

- Create one HCP Terraform agent pool.
- Create one token per agent instance (`agent-1`, `agent-2`, ... up to configured count, default: 5).
- Store each token under a unique AWS Secrets Manager path.
- Attach least-privilege IAM policy to allow only `GetSecretValue` and `DescribeSecret` for required token secrets.

## 5. Repository and File Conventions

Root module uses canonical Terraform filenames:

- `main.tf`: root resources and module calls
- `variables.tf`: all input variables (required first, then optional/alphabetical)
- `outputs.tf`: outputs (alphabetical)
- `providers.tf`: provider configuration
- `versions.tf`: Terraform and provider version constraints

`main.tf` should include:

- `Agent Host Infrastructure` section for networking, IAM, security groups, and EC2 host resources
- `HCP Terraform Agent Runtime` section for future agent bootstrap and runtime configuration

Shared data sources are defined in `main.tf` and placed next to resources that consume them.

## 6. Security Requirements

- Mark sensitive variables with `sensitive = true`.
- Do not commit local Terraform state or `.terraform` directories.
- Do not commit HCP Terraform agent tokens or API tokens.
- Secrets must be passed through secure workspace variables or a secret manager.
- Apply least privilege to IAM policies and network rules.
- Avoid exposing credentials in outputs, logs, or user data.

## 7. Functional Requirements

### FR-1 Infrastructure Provisioning

Terraform apply provisions VPC, subnets, routing, NAT, IAM profile, security group, and one EC2 host.

### FR-2 Private Host Placement

The EC2 host is provisioned in a private subnet without a public IP.

### FR-3 Secure Outbound Connectivity

The EC2 host can initiate outbound connections needed by HCP Terraform agent requirements while maintaining restricted inbound access.

### FR-4 Host Sizing for Five Agents

Default host sizing supports running up to 5 HCP Terraform agents, with sizing tunable through variables.

### FR-5 Secure AMI Selection

Infrastructure uses a secure Linux baseline image (Ubuntu Pro preferred) with option to override via variable.

### FR-6 Agent Token Automation

Terraform creates HCP Terraform agent tokens and stores them in AWS Secrets Manager.

### FR-7 Agent Runtime Automation

EC2 bootstrap installs tfc-agent, deploys a startup script, creates one systemd service per agent, and starts all configured agent services.

## 8. Non-Functional Requirements

- Maintainable Terraform structure and naming consistency.
- Compatibility with HCP Terraform and VCS-driven workflows.
- Clear, reproducible documentation for infrastructure and future runtime phases.
- No hardcoded secrets in Terraform code.

## 9. Acceptance Criteria

### AC-1

Repository follows canonical root Terraform file naming.

### AC-2

A VPC with public/private subnet topology and NAT-based outbound design is provisioned.

### AC-3

Exactly one EC2 instance is provisioned as the agent host.

### AC-4

EC2 host is private (no public IP by default) and managed through SSM.

### AC-5

Security groups do not allow unrestricted inbound access.

### AC-6

Default instance type and volume sizing are suitable for up to 5 agent processes.

### AC-7

AMI selection uses Ubuntu Pro (or a secure equivalent) unless explicitly overridden.

### AC-8

No HCP Terraform agent token is embedded in source code.

### AC-9

Terraform creates one HCP Terraform agent pool and `agent_count` tokens (default: 5).

### AC-10

Each token is stored in AWS Secrets Manager and EC2 IAM permissions are scoped to read only required token secrets.

### AC-11

The host starts one systemd unit per agent (`tfc-agent-1`, `tfc-agent-2`, etc.) through an automated bootstrap script.

## 10. Documentation Requirements

- Documentation must reflect phased delivery:
  - Phase 1: infrastructure baseline
  - Phase 2: agent runtime automation (token creation, secret storage, service deployment)
- Keep architecture statements synchronized across:
  - `AGENTS.md`
  - `docs/CONTRIBUTING.md`
  - `docs/SPECIFICATION.md`
- Remove references to deprecated Vault/RDS/ALB scope for this repository direction.

## 11. Risks and Mitigations

- Risk: Under-sizing the host for workload peaks.
  - Mitigation: set conservative defaults and allow instance type override.
- Risk: Excessive network egress permissions.
  - Mitigation: document required ports and keep rules minimal.
- Risk: Drift between code and documentation.
  - Mitigation: update specification, contributing guidance, and AGENTS instructions in the same change.

## 12. Change Control

Any architecture change in this file requires synchronized updates to:

- `AGENTS.md`
- `docs/CONTRIBUTING.md`
- `docs/SPECIFICATION.md` (this file)
- Terraform implementation files (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `versions.tf`)
