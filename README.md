# Terraform ECS Fargate Boilerplate

These are Terraform templates that can be used to set up web application stacks on AWS using [AWS ECS Fargate][fargate]. They provide a way to automate the process of creating and configuring the required resources on AWS.

These Terraform templates are designed to handle infrastructure-related concerns and therefore deploy a [default backend](environment/development/ecs.tf#L26). It is recommended to use the fargate CLI for managing application-specific concerns such as deploying actual application images and setting environment variables on top of the infrastructure created by these templates. The fargate CLI can be used to deploy applications locally or in continuous integration/continuous deployment (CI/CD) pipelines.

## Components


### Base

The following components are shared by all the envs.

| Name | Description | Optional |
|------|-------------|:---:|
| [main.tf][bm] | AWS provider, output |  |
| [state.tf][bs] | S3 bucket backend for storing Terraform remote state  |  |
| [ecr.tf][be] | ECR repository for application (all environments share)  |  ||

### environment/development

These components are for a specific environment. There should be a corresponding directory for each environment
that is needed.

| Name                                     | Description                                                                                                                                                                                                      | Optional |
|------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:----:|
| [main.tf][edm]                           | Terrform remote state, AWS provider, output                                                                                                                                                                      |  |
| [ecs.tf][ede]                            | ECS Cluster, Service, Task Definition, ecsTaskExecutionRole, CloudWatch Log Group                                                                                                                                |  |
| [lb.tf][edl]                             | ALB, Target Group, S3 bucket for access logs                                                                                                                                                                     |  |
| [security_group.tf][edn]                 | Security Group for ALB and Task                                                                                                                                                                                  |  |
| [load_balancer_http.tf][edlhttp]         | HTTP listener, NSG rule. Delete if HTTPS only                                                                                                                                                                    | Yes |
| [load_balancer_https.tf ][edlhttps]      | HTTPS listener, NSG rule. Delete if HTTP only                                                                                                                                                                    | Yes |
| [dashboard.tf][edd]                      | CloudWatch dashboard: CPU, memory, and HTTP-related metrics                                                                                                                                                      | Yes |
| [team_role.tf][edr]                      | Application Role for container                                                                                                                                                                                   | Yes |
| [cicd_user.tf][edc]                      | IAM user that can be used by CI/CD systems                                                                                                                                                                       | Yes |
| [performance_based_autoscaling.tf][edap] | Performance-based auto scaling                                                                                                                                                                                   | Yes |
| [time_based_autoscaling.tf][edat]        | Time-based auto scaling                                                                                                                                                                                          | Yes |
| [ssm_params.tf][ssm]                     | Add a CMK KMS key for use with SSM Parameter Store. Also gives ECS task definition role access to read secrets from parameter store.                                                                             | Yes |
| [ecs_event_streaming.tf][ees]            | Add an ECS event log dashboard                                                                                                                                                                                   | Yes |


## Usage

Typically, the base Terraform will only need to be run once, and then should only
need changes very infrequently. After the base is built, each environment can be built.

```
# Move into the base directory
$ cd base

# Sets up Terraform to run
$ terraform init

# Executes the Terraform run
$ terraform apply

# Now, move into the dev environment
$ cd ../env/dev

# Sets up Terraform to run
$ terraform init

# Executes the Terraform run
$ terraform apply
```

##### Important (after initial `terraform apply`)

The generated base `.tfstate` is not stored in the remote state S3 bucket. Ensure the base `.tfstate` is checked into your infrastructure repo. The default Terraform `.gitignore` [generated by GitHub](https://github.com/github/gitignore/blob/master/Terraform.gitignore) will ignore all `.tfstate` files; you'll need to modify this!

install
```shell
curl -s get-fargate-create.turnerlabs.io | sh
```

create an input vars file (`terraform.tfvars`)
```hcl
# app/env to scaffold
app = "my-app"
environment = "dev"
internal = true
container_port = "8080"
replicas = "1"
health_check = "/health"
region = "us-east-1"
aws_profile = "default"
saml_role = "admin"
vpc = "vpc-123"
private_subnets = "subnet-123,subnet-456"
public_subnets = "subnet-789,subnet-012"
tags = {
  application   = "my-app"
  environment   = "dev"
  team          = "my-team"
  customer      = "my-customer"
  contact-email = "me@example.com"
}
```

```shell
$ fargate-create -f terraform.tfvars
```


## Additional Information

+ [Base README][base]

+ [Environment `dev` README][env-dev]


Install pre-commit hook that checks terraform code for formatting
```sh
ln -s ../../pre-commit.sh .git/hooks/pre-commit
```

[fargate]: https://aws.amazon.com/fargate/
[bm]: ./base/main.tf
[bs]: ./base/state.tf
[be]: ./base/ecr.tf
[edm]: ./environment/development/main.tf
[ede]: ./environment/development/ecs.tf
[edl]: ./environment/development/load_balancer.tf
[edn]: ./environment/development/security_group.tf
[edlhttp]: ./environment/development/load_balancer_http.tf
[edlhttps]: ./environment/development/load_balancer_https.tf
[edd]: ./environment/development/dashboard.tf
[edr]: ./environment/development/team_role.tf
[edc]: ./environment/development/cicd_user.tf
[edap]: ./environment/development/performance_based_autoscaling.tf
[edat]: ./environment/development/time_based_autoscaling.tf
[ssm]: ./environment/development/ssm_params.tf
[ees]: ./environment/development/ecs_event_streaming.tf
[base]: ./base/README.md
[env-dev]: ./environment/development/README.md
