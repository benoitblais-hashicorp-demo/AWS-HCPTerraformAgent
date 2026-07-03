terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.79"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.66"
    }
  }
}
