locals {
  # KMS write actions
  kms_write_actions = [
    "kms:CancelKeyDeletion",
    "kms:CreateAlias",
    "kms:CreateGrant",
    "kms:CreateKey",
    "kms:DeleteAlias",
    "kms:DeleteImportedKeyMaterial",
    "kms:DisableKey",
    "kms:DisableKeyRotation",
    "kms:EnableKey",
    "kms:EnableKeyRotation",
    "kms:Encrypt",
    "kms:GenerateDataKey",
    "kms:GenerateDataKeyWithoutPlaintext",
    "kms:GenerateRandom",
    "kms:GetKeyPolicy",
    "kms:GetKeyRotationStatus",
    "kms:GetParametersForImport",
    "kms:ImportKeyMaterial",
    "kms:PutKeyPolicy",
    "kms:ReEncryptFrom",
    "kms:ReEncryptTo",
    "kms:RetireGrant",
    "kms:RevokeGrant",
    "kms:ScheduleKeyDeletion",
    "kms:TagResource",
    "kms:UntagResource",
    "kms:UpdateAlias",
    "kms:UpdateKeyDescription",
  ]

  # KMS read actions
  kms_read_actions = [
    "kms:Decrypt",
    "kms:DescribeKey",
    "kms:List*",
  ]

  # list of team users for policies
  team_user_ids = flatten([
    data.aws_caller_identity.current.user_id,
    data.aws_caller_identity.current.account_id,
    formatlist(
      "%s:%s",
      data.aws_iam_role.team_role_ssm.unique_id,
      var.secrets_team_users,
    ),
  ])

  # list of role users and team users for policies
  role_and_team_ids = flatten([
    "${aws_iam_role.ecsTaskExecutionRole.unique_id}:*",
    local.team_user_ids,
  ])
}

# get the team user info so we can get the unique_id
data "aws_iam_role" "team_role_ssm" {
  name = var.team_role
}

# The users (email addresses) from the team role to give access
# case sensitive
variable "secrets_team_users" {
  type = list(string)
}

# kms key used to encrypt ssm parameters
resource "aws_kms_key" "ssm" {
  description             = "ssm parameters key for ${var.application}-${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags
  policy                  = data.aws_iam_policy_document.ssm.json
}

resource "aws_kms_alias" "ssm" {
  name          = "alias/${var.application}-${var.environment}"
  target_key_id = "${aws_kms_key.ssm.id}"
}

data "aws_iam_policy_document" "ssm" {
  statement {
    sid    = "DenyWriteToAllExceptTeamUsers"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = local.kms_write_actions
    resources = ["*"]

    condition {
      test     = "StringNotLike"
      variable = "aws:userId"
      values   = local.team_user_ids
    }
  }

  statement {
    sid    = "DenyReadToAllExceptRoleAndTeamUsers"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = local.kms_read_actions
    resources = ["*"]

    condition {
      test     = "StringNotLike"
      variable = "aws:userId"
      values   = local.role_and_team_ids
    }
  }

  statement {
    sid    = "AllowWriteToTeamUsers"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = local.kms_write_actions
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:userId"
      values   = local.team_user_ids
    }
  }

  statement {
    sid    = "AllowReadRoleAndTeamUsers"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = local.kms_read_actions
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:userId"
      values   = local.role_and_team_ids
    }
  }
}

# allow ecs task execution role to read this app's params
resource "aws_iam_policy" "ecsTaskExecutionRole_ssm" {
  name        = "${var.application}-${var.environment}-ecs-ssm"
  path        = "/"
  description = "allow ecs task execution role to read this app's parameters"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters"
      ],
      "Resource": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.application}/${var.environment}/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_ssm" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = aws_iam_policy.ecsTaskExecutionRole_ssm.arn
}
# This is a command used to store a secure password in the SSM parameter store using the specified KMS key
output "ssm_add_secret" {
  value = "aws ssm put-parameter --overwrite --type \"SecureString\" --key-id \"${aws_kms_alias.ssm.name}\" --name \"/${var.application}/${var.environment}/PASSWORD\" --value \"password\""
}
# This is a command that can be used to set a "PASSWORD" environment variable for a Fargate service using the AWS SSM.
output "ssm_add_secret_ref" {
  value = "fargate service env set --secret PASSWORD=/${var.application}/${var.environment}/PASSWORD"
}

output "ssm_key_id" {
  value = aws_kms_key.ssm.key_id
}