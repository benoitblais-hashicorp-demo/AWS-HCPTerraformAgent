# AGENTS.md for Terraform Project

This file provides instructions for AI coding agents working on this Terraform project.

## Project Overview

This project provisions AWS infrastructure to host HCP Terraform agents.
The target architecture is one EC2 instance that runs a configurable number of HCP Terraform agent processes (default: 5).
The file `docs/SPECIFICATION.md` is intended to be the source of truth for architecture decisions, requirements, and acceptance criteria.

### Architecture Decisions

- Provision exactly one Linux EC2 instance dedicated to running HCP Terraform agents.
- Run a configurable number of HCP Terraform agents on that host as independent services (default: 5).
- Deliver in phases: implement secure infrastructure first, then configure agent runtime in a follow-up phase.
- Automate HCP Terraform agent pool and token creation with the `tfe` provider.
- Store per-agent tokens in AWS Secrets Manager and never expose token values in outputs.
- Start each agent as a dedicated systemd service calling a shared startup script.
- Keep agent runtime configuration externalized through variables and templates.
- Do not hardcode HCP Terraform agent tokens or secrets in Terraform source files.
- Use IAM least privilege for the EC2 instance profile and networking resources.

## Module and Repository Structure

Organize the project using standard root-module file names:

```text
├── .gitignore
├── LICENSE
├── README.md
├── main.tf
├── outputs.tf
├── providers.tf
├── variables.tf
├── versions.tf
├── docs/
│   ├── CODE_OF_CONDUCT.md
│   ├── CONTRIBUTING.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── README_footer.md
│   ├── README_header.md
│   ├── SPECIFICATION.md
│   ├── SECURITY.md
```

### Required Files and Directories

- `README.md` - Required in the root module. Generated automatically (for example, via terraform-docs). Do not edit manually.
- `docs/SPECIFICATION.md` - Source of truth for architecture decisions, implementation requirements, and acceptance criteria.
- `docs/README_header.md` - Describe the purpose of the code and provide required context.
- `docs/README_footer.md` - Provide links to external documentation used to generate the code.
- `main.tf` - Root module resources, modules, and data sources placed next to the resources that consume them.
- `outputs.tf` - Root module outputs (alphabetical order).
- `providers.tf` - Provider configurations.
- `variables.tf` - Global input variable definitions (alphabetical order with required variables at the top).
- `versions.tf` - Terraform version and provider requirements.

### Main.tf Layout

- Include a dedicated `Agent Host Infrastructure` section for networking, IAM, and EC2 host resources.
- Keep the host in private subnets and use NAT-based outbound internet access.
- Include a dedicated `HCP Terraform Agent Runtime` section for bootstrap/user_data templates and service configuration.
- Keep token lifecycle resources (`tfe_agent_pool`, `tfe_agent_token`, Secrets Manager) in the runtime section.
- Keep shared data sources close to the resources that consume them.

## Tools and Frameworks

- AI agents should format generated HCL according to Terraform style conventions.
- If local Terraform commands are unavailable in the current workflow, still produce valid HCL and keep formatting clean.
- Use terraform-docs to generate `README.md` from `docs/README_header.md` and `docs/README_footer.md` where applicable.

## README_header.md

When editing or creating `docs/README_header.md`, ensure it contains:

- A description of the general purpose of the code.
- A `Permissions` section containing required AWS and HCP Terraform permissions.
- An `Authentications` section describing AWS and HCP Terraform authentication methods.
- A `Features` section containing key features managed by the code, including hosting a configurable number of HCP Terraform agents (default: 5).

## README_footer.md

When editing or creating `docs/README_footer.md`, ensure it contains:

- An `External Documentation` section with links used to develop the code (for example, HCP Terraform Agent docs, AWS Provider docs, EC2 docs, and cloud-init/user_data references).

## Code Guidelines

Refer to CONTRIBUTING.md for general coding guidelines. Apply HashiCorp Terraform style conventions for all generated code.

## Resource Naming

- Use descriptive nouns separated by underscores.
- Do not include the resource type in the resource name.
- Wrap resource type and name in double quotes.
- Example: `resource "aws_instance" "agent_host"` not `resource "aws_instance" "aws_instance_agent_host"`.

## Version Management

- Prefer the pessimistic constraint operator (`~>`) for modules and providers to allow safe compatible updates.
- Avoid the equals (`=`) operator unless you need exact version pinning for reproducibility or a known issue.
- Pin Terraform with `required_version` in the `terraform` block.

## Provider Configuration

- Always include a default AWS provider configuration.
- Define providers in `providers.tf`.
- Define the default provider first, then aliased providers if needed.
- Use `alias` as the first parameter in non-default provider blocks.

## Security and Secrets

- Never commit `.terraform` directories or local state files.
- Do not commit HCP Terraform agent tokens, API tokens, private keys, or secret values.
- Pass sensitive values through secure workspace variables or secret managers.
- Mark sensitive Terraform inputs with `sensitive = true`.
- Avoid exposing credentials in outputs, logs, or user_data where possible.
- Prefer SSM Session Manager for administration and keep direct SSH disabled by default.

## State Management

- State storage is managed by HCP Terraform workspaces in VCS-driven workflows.
- If cross-workspace sharing is required, use supported remote state or workspace output patterns.

## Consistency Note

If `docs/SPECIFICATION.md` diverges from the architecture above, update `docs/SPECIFICATION.md`, this file, and Terraform implementation files together in the same change.
