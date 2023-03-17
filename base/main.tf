terraform {
  required_version = ">= 0.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0, < 5.0.0"
    }
  }
}

/**
 * main.tf
 * The main entry point for Terraform run
 * See variables.tf for common variables
 * See ecr.tf for creation of Elastic Container Registry for all environments
 * See terraform_remote_state_management.tf for creation of S3 bucket for remote terraform_remote_state_management
 */

# Provider Configuration (AWS)
# https://www.terraform.io/docs/providers/aws/index.html
provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

/**
 * Outputs
 * Results from a successful Terraform run
 * Use `terraform output [name]` to view the results after a successful run
 */

# Returns the name of the ECR registry, this will be used later in various scripts
output "docker_registry" {
  value = aws_ecr_repository.application.repository_url
}

# Returns the name of the S3 bucket that will be used in later Terraform files
#
output "bucket" {
  value = module.terraform_remote_state_management.bucket
}
