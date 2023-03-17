# Environment Dev Terraform

Creates the dev environment's infrastructure. These templates are designed to be customized.
The optional components can be removed by simply deleting the `.tf` file.


## Components

| Name                                     | Description                                                                                                                          | Optional |
|------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|:----:|
| [main.tf][edm]                           | Terrform remote state, AWS provider, output                                                                                          |  |
| [ecs.tf][ede]                            | ECS Cluster, Service, Task Definition, ecsTaskExecutionRole, CloudWatch Log Group                                                    |  |
| [load_balancer.tf][edl]                  | ALB, Target Group, S3 bucket for access logs                                                                                         |  |
| [security_group.tf][edn]                 | Security Group for ALB and Task                                                                                                      |  |
| [load_balancer_http.tf][edlhttp]         | HTTP listener, SG rule. Delete if HTTPS only                                                                                         | Yes |
| [load_balancer_https.tf][edlhttps]       | HTTPS listener, SG rule. Delete if HTTP only                                                                                         | Yes |
| [dashboard.tf][edd]                      | CloudWatch dashboard: CPU, memory, and HTTP-related metrics                                                                          | Yes |
| [role.tf][edr]                           | Application Role for container                                                                                                       | Yes |
| [cicd_user.tf][edc]                      | IAM user that can be used by CI/CD systems                                                                                           | Yes |
| [performance_based_autoscaling.tf][edap] | Performance-based auto scaling                                                                                                       | Yes |
| [time_based_autoscaling.tf][edat]        | Time-based auto scaling                                                                                                              | Yes |
| [ssm_params.tf][ssm]                     | Add a CMK KMS key for use with SSM Parameter Store. Also gives ECS task definition role access to read secrets from parameter store. | Yes |



## Usage

```
# Sets up Terraform to run
$ terraform init

# Executes the Terraform run
$ terraform apply
```


## Inputs

| Name                        | Description                                                                                                                                                                       | Type |                   Default                    | Required |
|-----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:----:|:--------------------------------------------:|:-----:|
| application                 | The application's name                                                                                                                                                            | string |                      -                       | yes |
| aws_profile                 | The AWS Profile to use                                                                                                                                                            | string |                      -                       | yes |
| SSL_certificate_arn         | The ARN for the SSL certificate                                                                                                                                                   | string |                      -                       | yes |
| container_name              | The name of the container to run                                                                                                                                                  | string |                    `app`                     | no |
| container_port              | The port the container will listen on, used for load balancer health check Best practice is that this value is higher than 1024 so the container processes isn't running at root. | string |                      -                       | yes |
| default_container_image     | The default docker image to deploy with the infrastructure.                                                                                                                       | string | `quay.io/turner/turner-defaultbackend:0.2.0` | no |
| deregistration_delay        | The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused                                                    | string |                     `30`                     | no |
| ecs_high_cpu_threshold_per  | If the average CPU utilization over a minute rises to this threshold, the number of containers will be increased (but not above ecs_autoscale_max_instances).                     | string |                     `80`                     | no |
| ecs_low_cpu_threshold_per   | If the average CPU utilization over a minute drops to this threshold, the number of containers will be reduced (but not below ecs_autoscale_min_instances).                       | string |                     `20`                     | no |
| ecs_autoscale_max_instances | The maximum number of containers that should be running. used by both autoscale-perf.tf and autoscale.time.tf                                                                     | string |                     `8`                      | no |
| ecs_autoscale_min_instances | The minimum number of containers that should be running. Must be at least 1. used by both autoscale-perf.tf and autoscale.time.tf For production, consider using at least "2".    | string |                     `1`                      | no |
| environment                 | The environment that is being built                                                                                                                                               | string |                      -                       | yes |
| health_check                | The path to the health check for the load balancer to know if the container(s) are ready                                                                                          | string |                      -                       | yes |
| health_check_interval       | How often to check the liveliness of the container                                                                                                                                | string |                     `30`                     | no |
| health_check_matcher        | What HTTP response code to listen for                                                                                                                                             | string |                    `200`                     | no |
| health_check_timeout        | How long to wait for the response on the health check path                                                                                                                        | string |                     `10`                     | no |
| https_port                  | The port to listen on for HTTPS, always use 443                                                                                                                                   | string |                    `443`                     | no |
| internal                    | Whether the application is available on the public internet, also will determine which subnets will be used (public or private)                                                   | string |                    `true`                    | no |
| lb_port                     | The port the load balancer will listen on                                                                                                                                         | string |                     `80`                     | no |
| lb_protocol                 | The load balancer protocol                                                                                                                                                        | string |                    `HTTP`                    | no |
| logs_retention_in_days      | Specifies the number of days you want to retain log events                                                                                                                        | int |                      90                      | no |
| private_subnets             | The private subnets, minimum of 2, that are a part of the VPC(s)                                                                                                                  | string |                      -                       | yes |
| public_subnets              | The public subnets, minimum of 2, that are a part of the VPC(s)                                                                                                                   | string |                      -                       | yes |
| region                      | The AWS region to use for the dev environment's infrastructure`.                                                                                                                  | string |                 `us-west-2`                  | no |
| replicas                    | How many containers to run                                                                                                                                                        | string |                     `1`                      | no |
| team_role                   | The IAM role to use for adding users to the ECR policy                                                                                                                            | string |                      -                       | yes |
| scale_down_cron             | Default scale down at 7 pm every day                                                                                                                                              | string |             `cron(0 23 * * ? *)`             | no |
| scale_down_to_max_capacity  | The maximum number of containers to scale down to.                                                                                                                                | string |                     `0`                      | no |
| scale_down_to_min_capacity  | The mimimum number of containers to scale down to. Set this and `scale_down_to_max_capacity` to 0 to turn off service on the `scale_down_cron` schedule.                          | string |                     `0`                      | no |
| time_to_scale_up_cron       | Default scale up at 7 am weekdays, this is UTC so it doesn't adjust to daylight savings https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html           | string |          `cron(0 11 ? * MON-FRI *)`          | no |
| secrets_team_users          | The users (email addresses) from the saml role to give access                                                                                                                     | list |                      -                       | yes |
| tags                        | Tags for the infrastructure                                                                                                                                                       | map |                      -                       | yes |
| vpc                         | The VPC to use for the Fargate cluster                                                                                                                                            | string |                      -                       | yes |

## Outputs

| Name | Description |
|------|-------------|
| aws_profile | Command to set the AWS_PROFILE |
| cicd_keys | The AWS keys for the CICD user to use in a build system |
| deploy | Command to deploy a new task definition to the service using Docker Compose |
| docker_registry | The URL for the docker image repo in ECR |
| lb_dns | The load balancer DNS name |
| scale_out | Command to scale out the number of tasks (container replicas) |
| scale_up | Command to scale up cpu and memory |
| status | Command to view the status of the Fargate service |



[edm]: main.tf
[ede]: ecs.tf
[edl]: load_balancer.tf 
[edn]: security_group.tf
[edlhttp]: load_balancer_http.tf
[edlhttps]: load_balancer_https.tf
[edd]: dashboard.tf
[edr]: team_role.tf
[edc]: cicd_user.tf
[edap]: performance_based_autoscaling.tf
[edat]: time_based_autoscaling.tf
[ssm]: ssm_params.tf
