### terraform-remote-state

A reusable Terraform module that configures an s3 bucket for use with Terraform's remote state feature.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| application | the application that will be using this remote state | string | - | yes |
| block\_public\_access | ensure `bucket` access is "Bucket and objects not public" | bool | `true` | no |
| multipart\_days |  | string | `3` | no |
| multipart\_delete | incomplete multipart upload deletion | string | `true` | no |
| role | the primary role that will be used to access the tf remote state | string | - | yes |
| additional\_roles | additional roles that will be granted access to the remote state | list of strings | \[] | no |
| dynamodb\_state\_locking | if enabled, creates a dynamodb table to be used to store state lock status | bool | `false` | no |
| tags | tags to apply the created S3 bucket | map | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| bucket | the created bucket |
| dynamodb_lock_table | name of dynamodb lock table, if created |

