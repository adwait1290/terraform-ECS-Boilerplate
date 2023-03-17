/*
 * variables.tf
 * Common vars for all modules
 */

# The AWS region to deploy into
variable "region" {
  default = "us-west-2"
}

# The AWS profile to use. Same as AWS_PROFILE
variable "aws_profile" {
}

# The role that will have access to the S3 bucket and DynamoDB table.
variable "team_role" {
}

# Variable used to enable the DynamoDB state locking feature
variable "dynamodb_state_locking" {
  default = "false"
}

# Name of the application. Used for naming resources.
variable "application" {
}

# A map of the tags to apply to various resources. The required tags are:
# `application`, name of the app;
# `environment`, the environment being created;
# `team`, team responsible for the application;
# `contact-email`, contact email for the _team_;
# and `customer`, who the application was create for.
variable "tags" {
  type = map(string)
}
