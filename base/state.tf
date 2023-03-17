/**
 * Default state management without anything special like DynamoDB lock tables.
 */

module "terraform_remote_state_management" {
  source      = "terraform_remote_state_management"
  role        = var.team_role
  application = var.application
  dynamodb_state_locking = "true" # Using true since default is false
  tags        = var.tags
}