/**
 * Elastic Container Service (ECS)
 * This component is necessary for creating an ECS (Amazon Elastic Container Service) service on Fargate. It will
 * create a Fargate cluster based on the application name and environment, and then create a "Task Definition" which
 * is required to run Docker containers. The component also creates an ECS service, attaches a
 * load balancer (created in the load_balancer.tf file) to the service, sets up the required networking, creates
 * a role with the appropriate permissions, and ensures that logs are captured in CloudWatch.
 *
 * NOTE: During the initial build process, a "default backend" web service will be installed. This service simply
 * returns a HTTP 200 OK response. It is important to uncomment the lines noted below once you have successfully
 * migrated the real application containers to the task definition, as this will ensure that the default backend
 * is no longer used."
 */

# Number of Containers to run
variable "replicas" {
  default = "1"
}

variable "container_name" {
  default = "application"
}

# Min number of containers to run. Use at least 2 for production
variable "ecs_autoscaling_min_instances" {
  default = "1"
}

# Max number of containers that should run
variable "ecs_autoscaling_max_instances" {
  default = "8"
}

resource "aws_ecs_cluster" "application" {
  name = "${var.application}-${var.environment}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = var.tags
}

# The default Docker image that is deployed with the infrastructure is specified here. The source code for the Turner default
# backend image can be found at https://github.com/turnerlabs/turner-defaultbackend.
#
# TL;DR - This is a trivial web service that returns a 501 Not Implemented response for all requests except for health
# checks, which receive a 200 OK response. Only used for testing.
variable "default_container_image" {
    default = "quay.io/turner/turner-defaultbackend:0.2.0"
}

resource "aws_appautoscaling_target" "app_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.application.name}/${aws_ecs_service.application.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.ecs_autoscaling_min_instances
  min_capacity       = var.ecs_autoscaling_max_instances
}

resource "aws_ecs_task_definition" "application" {
  family                   = "${var.application}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  # defined in role.tf
  task_role_arn = aws_iam_role.app_role.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "${var.container_name}",
    "image": "${var.default_container_image}",
    "essential": true,
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": ${var.container_port},
        "hostPort": ${var.container_port}
      }
    ],
    "environment": [
      {
        "name": "PORT",
        "value": "${var.container_port}"
      },
      {
        "name": "HEALTHCHECK",
        "value": "${var.health_check}"
      },
      {
        "name": "ENABLE_LOGGING",
        "value": "false"
      },
      {
        "name": "PRODUCT",
        "value": "${var.application}"
      },
      {
        "name": "ENVIRONMENT",
        "value": "${var.environment}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/fargate/service/${var.application}-${var.environment}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION


  tags = var.tags
}

resource "aws_ecs_service" "application" {
  name            = "${var.application}-${var.environment}"
  cluster         = aws_ecs_cluster.application.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.application.arn
  desired_count   = var.replicas

  network_configuration {
    security_groups = [aws_security_group.security_group_task.id]
    subnets         = split(",", var.private_subnets)
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.id
    container_name   = var.container_name
    container_port   = var.container_port
  }

  tags                    = var.tags
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  # workaround for https://github.com/hashicorp/terraform/issues/12634
  depends_on = [aws_alb_listener.http]

  # [after initial apply] don't override changes made to task_definition
  # from outside of terraform (i.e.; fargate cli)
  lifecycle {
    ignore_changes = [task_definition]
  }
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.application}-${var.environment}-ecs"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

variable "logs_retention_in_days" {
  type        = number
  default     = 90
  description = "Specifies the # of days you want to retain log events"
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/fargate/service/${var.application}-${var.environment}"
  retention_in_days = var.logs_retention_in_days
  tags              = var.tags
}
