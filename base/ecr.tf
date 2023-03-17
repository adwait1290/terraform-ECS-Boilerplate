/*
 * ecr.tf
 * Creates a Amazon Elastic Container Registry (ECR) for the application
 * https://aws.amazon.com/ecr/
 */


# Tag mutability setting for the repo (defaults to IMMUTABLE)
variable "image_tag_mutability" {
  type = string
  default = "IMMUTABLE"
  description = "The tag mutability setting for the repository. Defaults to IMMUTABLE"
}

# Create an ECR repository at the application/image level
resource "aws_ecr_repository" "application" {
  name                 = var.application
  image_tag_mutability = var.image_tag_mutability
}

# Use this data source to get the access to the effective Account ID, User ID, and ARN in which Terraform is authorized.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
data "aws_caller_identity" "current" {
}

# Grant access to team users
resource "aws_ecr_repository_policy" "app" {
  repository = aws_ecr_repository.application.name
  policy     = data.aws_iam_policy_document.ecr.json
}

data "aws_iam_policy_document" "ecr" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
      "ecr:GetLifecyclePolicy",
      "ecr:PutLifecyclePolicy",
      "ecr:DeleteLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:StartLifecyclePolicyPreview",
    ]

    principals {
      type = "AWS"
      # Add the team roles for every member on the "team"
      identifiers = [
        "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/${var.team_role}/*****@*********.com",
      ]
    }
  }
}
