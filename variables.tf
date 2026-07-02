variable "tfe_organization" {
  description = "(Required) HCP Terraform organization where the agent pool and tokens are created."
  type        = string
}

variable "agent_count" {
  description = "(Optional) Number of HCP Terraform agents to run on the EC2 host and number of tokens to create."
  type        = number
  default     = 5

  validation {
    condition     = var.agent_count >= 1 && var.agent_count <= 5
    error_message = "agent_count must be between 1 and 5."
  }
}

variable "agent_host_ami_id" {
  description = "(Optional) Custom AMI ID for the EC2 host. If empty, Ubuntu Pro LTS AMI discovery is used."
  type        = string
  default     = ""
}

variable "agent_host_instance_type" {
  description = "(Optional) EC2 instance type for the host running up to 5 HCP Terraform agents."
  type        = string
  default     = "t3.large"

  validation {
    condition = contains([
      "t3.large",
      "t3.xlarge",
      "m6i.large",
      "m7i.large",
      "m6a.large"
    ], var.agent_host_instance_type)
    error_message = "agent_host_instance_type must be one of: t3.large, t3.xlarge, m6i.large, m7i.large, or m6a.large."
  }
}

variable "agent_host_root_volume_size_gb" {
  description = "(Optional) Root disk size in GiB for the EC2 host."
  type        = number
  default     = 64

  validation {
    condition     = var.agent_host_root_volume_size_gb >= 20
    error_message = "agent_host_root_volume_size_gb must be at least 20 GiB."
  }
}

variable "availability_zone_count" {
  description = "(Optional) Number of availability zones used for public/private subnets."
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zone_count >= 2 && var.availability_zone_count <= 3
    error_message = "availability_zone_count must be between 2 and 3."
  }
}

variable "aws_region" {
  description = "(Optional) AWS region for infrastructure deployment."
  type        = string
  default     = "ca-central-1"
}

variable "environment" {
  description = "(Optional) Environment tag value."
  type        = string
  default     = "demo"
}

variable "management_cidrs" {
  description = "(Optional) CIDR blocks allowed for SSH management. Leave empty to disable SSH ingress."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.management_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All management_cidrs values must be valid CIDR blocks."
  }
}

variable "project_name" {
  description = "(Optional) Project name used in resource naming and tagging."
  type        = string
  default     = "hcp-terraform-agent-host"
}

variable "tfc_agent_run_user" {
  description = "(Optional) Linux user that runs the tfc-agent services."
  type        = string
  default     = "terraform-agent"
}

variable "tfc_agent_token_secret_prefix" {
  description = "(Optional) AWS Secrets Manager prefix where agent tokens are stored."
  type        = string
  default     = "/hcp-tf-agent"
}

variable "tfc_agent_version" {
  description = "(Optional) HCP Terraform agent version to install on the EC2 host. Set to latest to resolve at runtime."
  type        = string
  default     = "latest"
}

variable "tfe_agent_pool_name" {
  description = "(Optional) Name of the HCP Terraform agent pool."
  type        = string
  default     = "aws"
}

variable "vpc_cidr" {
  description = "(Optional) CIDR block for the VPC."
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}
