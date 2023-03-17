/**
 * This module allows you to set up autoscaling based on time. This can be useful if you want to automatically
 * adjust the number of containers running your service during certain periods of the day, such as during non-business
 * hours. For example, you may want to scale down the number of containers during off-peak hours to save on resource
 * usage and cost, and then scale up again when demand for the service increases. This time-based autoscaling feature
 * can help you to manage your resources more effectively and ensure that your service is running optimally at all
 * times.
 */

# Default scale up at 7 am weekdays, this is UTC so it doesn't adjust to daylight savings
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
variable "time_to_scale_up_cron" {
  default = "cron(0 11 ? * MON-FRI *)"
}

# Default scale down at 7 pm every day
variable "time_to_scale_down_cron" {
  default = "cron(0 23 * * ? *)"
}

# The mimimum number of containers to scale down to. Set this and `scale_down_to_max_capacity` to 0 to turn off
# service on the `scale_down_cron` schedule.
variable "scale_down_to_min_capacity" {
  default = 0
}

# The maximum number of containers to scale down to.
variable "scale_down_to_max_capacity" {
  default = 0
}
# Scales the number of containers running your service in response to changes in demand
# The preferred running capacity, or the ideal number of containers, is determined by the values of the
# ecs_autoscale_min_instances and ecs_autoscale_max_instances variables. When demand for the service increases, the
# number of containers will be gradually increased up to the maximum specified by ecs_autoscale_max_instances. When
# demand decreases, the number of containers will be reduced down to the minimum specified by
# ecs_autoscale_min_instances. By continuously adjusting the number of containers to match the demand for the
# service, this autoscaling mechanism helps to ensure that the service is running optimally at all times.

# Scales service back up to preferred running capacity defined by the `ecs_autoscale_min_instances` and
# `ecs_autoscale_max_instances` variables
resource "aws_appautoscaling_scheduled_action" "app_autoscale_time_up" {
  name = "app-autoscale-time-up-${var.application}-${var.environment}"

  service_namespace  = aws_appautoscaling_target.app_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.app_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.app_scale_target.scalable_dimension
  schedule           = var.time_to_scale_up_cron

  scalable_target_action {
    min_capacity = aws_appautoscaling_target.app_scale_target.min_capacity
    max_capacity = aws_appautoscaling_target.app_scale_target.max_capacity
  }
}

# Scales service down to capacity defined by the
# `scale_down_to_min_capacity` and `scale_down_to_max_capacity` variables.
resource "aws_appautoscaling_scheduled_action" "app_autoscale_time_down" {
  name = "app-autoscale-time-down-${var.application}-${var.environment}"

  service_namespace  = aws_appautoscaling_target.app_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.app_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.app_scale_target.scalable_dimension
  schedule           = var.time_to_scale_down_cron

  scalable_target_action {
    min_capacity = var.scale_down_to_min_capacity
    max_capacity = var.scale_down_to_max_capacity
  }
}
