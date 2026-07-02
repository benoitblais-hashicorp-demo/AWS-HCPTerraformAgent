# Contributing

Thank you for your interest in contributing. This repository uses Terraform to provision AWS infrastructure for HCP Terraform agents. The target architecture is one EC2 host running a configurable number of HCP Terraform agent processes (default: 5). Please review these guidelines before contributing.

## Architecture Paradigm: HCP Terraform Workspaces

This project leverages standard Terraform configurations and uses HCP Terraform workspaces for remote execution and state management.

* **No Local State or CLI Applies:** Do not run `terraform apply` locally. All pushes to the main branch are evaluated and deployed by HCP Terraform natively via a VCS-driven workflow.
* **State Management:** Data sharing between distinct configurations relies on standard data sources or workspace output patterns where cross-workspace values are required.
* **Dynamic Credentials:** The project leverages dynamic provider credentials natively supported by Terraform Cloud/Enterprise.

## Development Workflow

1. **Fork & Branch:** Create a branch for your feature or bug fix.
2. **Write Code:** Modify the Terraform configurations (`main.tf`, `variables.tf`, etc.) following our styling guidelines.
3. **Preserve Architecture Intent:** Keep changes aligned to one EC2 host and a configurable HCP Terraform agent count (default: 5) unless the specification is intentionally updated.
4. **Follow Delivery Phases:** Infrastructure baseline changes come first (VPC, IAM, EC2 hardening), then agent runtime configuration in subsequent changes.
5. **Format:** Formatting checks are enforced by CI/CD. Local formatting is optional for contributor convenience.
6. **Open a Pull Request:** Fill out the provided PR template outlining your changes.

## Code Guidelines

* **Minimalism:** Favor readability and simplicity over highly complex abstractions.
* **Variable Descriptions:** Every variable must have a clear `description` and `type`.
* **Version Constraints:** Use the pessimistic operator (`~>`) for provider and module versions to ensure stability without strict lock-in. Pin the Terraform version using `required_version` in the `terraform` block.
* **Naming Conventions:** Use `snake_case` for all resource and variable names. Avoid including the resource type in the name.
* **Runtime Configuration:** Keep HCP Terraform agent bootstrap and runtime settings configurable via variables/templates rather than hardcoded values.
* **Token Automation:** Create agent tokens with Terraform (`tfe` provider) and store them in AWS Secrets Manager for host retrieval.
* **Service Management:** Run each agent as an independent systemd service to isolate failures and simplify restarts.
* **Network Security:** Keep agent hosts private by default, with outbound-only access required for HCP Terraform agent operations.

## Security Check

* Never commit `.terraform` folders, `.tfstate` files, or `.tfvars` files containing actual secrets.
* Never commit HCP Terraform agent tokens, API tokens, private keys, or plaintext credentials.
* Access secrets securely via workspace variables or a secret manager. Set `sensitive = true` for sensitive variables across all definitions.
* Prefer SSM Session Manager over direct SSH access.

If you find a security vulnerability, please refer to our `SECURITY.md` for reporting procedures.
