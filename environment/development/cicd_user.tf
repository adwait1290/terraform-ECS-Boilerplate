# This creates a user with access keys specifically for use in a continuous integration and continuous
# delivery (CI/CD) build system.
resource "aws_iam_user" "cicd" {
  name = "srv_${var.application}_${var.environment}_cicd"
}

resource "aws_iam_access_key" "cicd_keys" {
  user = aws_iam_user.cicd.name
}

# This grants the necessary permissions to allow a user to deploy applications.
data "aws_iam_policy_document" "cicd_policy" {
  # Enables a user to push and pull Docker images to and from a registry, allowing them to store, manage, and access
  # the images as needed.
  statement {
    sid = "ecr"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]

    resources = [
      data.aws_ecr_repository.ecr.arn,
    ]
  }

  # Allows a user to deploy applications to ECS (Amazon Elastic Container Service), enabling them to run and
  # manage containerized applications within the ECS environment.
  statement {
    sid = "ecs"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:UpdateService",
      "ecs:RegisterTaskDefinition",
    ]

    resources = [
      "*",
    ]
  }

  # This  enables a user to run an ECS task using task execution and application roles, which provide the necessary
  # permissions and access to execute the task within the ECS environment.
  statement {
    sid = "approle"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      aws_iam_role.app_role.arn,
      aws_iam_role.ecsTaskExecutionRole.arn,
    ]
  }
}

resource "aws_iam_user_policy" "cicd_user_policy" {
  name   = "${var.application}_${var.environment}_cicd"
  user   = aws_iam_user.cicd.name
  policy = data.aws_iam_policy_document.cicd_policy.json
}

data "aws_ecr_repository" "ecr" {
  name = var.application
}

# The AWS keys that the CICD user can use in the build system are for authentication and access to AWS resources
# and services
output "cicd_keys" {
  value = "terraform show -json | jq '.values.root_module.resources | .[] | select ( .address == \"aws_iam_access_key.cicd_keys\") | { AWS_ACCESS_KEY_ID: .values.id, AWS_SECRET_ACCESS_KEY: .values.secret }'"
}

# The URL for the Docker image repository in ECR (Amazon Elastic Container Registry) is used to access and manage
# the Docker images stored in the repository.
output "docker_registry" {
  value = data.aws_ecr_repository.ecr.repository_url
}
