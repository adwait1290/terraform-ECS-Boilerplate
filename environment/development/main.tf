terraform {
  required_version = ">= 0.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0, < 5.0.0"
    }
  }

  backend "s3" {
    region          = "us-west-2"
    profile         = ""
    bucket          = ""
    key             = "dev.terraform.tfstate"
    dynamodb_table  = "dev.terraform.tfstatelocking"
  }
}

# The AWS Profile to use
variable "aws_profile" {
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

# output

# This is the command to check the status of the Fargate service.
output "status" {
  value = "fargate service info"
}

# This is a command to deploy a new task definition to the service using Docker Compose
output "deploy" {
  value = "fargate service deploy -f docker-compose.yml"
}

# This is a command to vertically scale (scale up CPU and memory)
output "scale_up" {
  value = "fargate service update -h"
}

# This is a command to horizontally scale out the number of tasks (container replicas)
output "scale_out" {
  value = "fargate service scale -h"
}

# This is a command to set the AWS_PROFILE
output "aws_profile" {
  value = var.aws_profile
}
