/**
 * This module is designed to automatically scale the number of containers in response to changes in CPU utilization.
 * The number of containers will be adjusted within the range specified, with the goal of maintaining the desired level
 * of CPU utilization. As traffic to the application increases or decreases, the number of instances will be
 * automatically adjusted to meet the demands of the workload. This autoscaling mechanism is particularly well-suited
 * for applications that are CPU-bound, as it will automatically add or remove instances as needed to ensure that the
 * application has sufficient capacity to handle the traffic.
 *
 * To ensure a smooth and gradual response to changes in traffic, it is recommended to set the
 * ecs_autoscale_min_instances variable to a higher value if you anticipate a sudden increase in traffic for a
 * scheduled event, such as a sporting event or election. Additionally, you should ensure that the
 * ecs_autoscale_max_instances variable is set to a value that is higher than ecs_autoscale_min_instances, so that the
 * maximum number of instances is never below the minimum number. This will help to prevent disruptions or bottlenecks
 * in service during periods of increased traffic.

 * NOTE : To disable autoscaling, set `ecs_autoscale_min_instances` and `ecs_autoscale_max_instances` to the same number
 * (your desired number of containers).
 *
 * NOTE :  default value of `ecs_autoscale_min_instances` is 1.  For production, consider using a higher
 * number(minimum of 2)
 *
 * To prevent frequent fluctuations in the number of containers, it is recommended to maintain a significant
 * ["deadband"](https://en.wikipedia.org/wiki/Deadband) or gap between the ecs_low_cpu_threshold_per and
 * ecs_high_cpu_threshold_per values. This will ensure that the number of containers is not constantly being scaled
 * up and down in response to minor changes in CPU utilization. If ecs_autoscale_min_instances is set to 1, it is
 * advisable to set ecs_as_cpu_high_threshold_per to a value that is more than twice ecs_low_cpu_threshold_per.
 * This will help to prevent excessive scaling and ensure that the number of containers remains within a stable range.
 *
 * In the CloudWatch section of the AWS Console, you may notice that the alarms created by this module are displayed in
 * an "ALARM" state, which is typically shown in red. This is a normal occurrence and does not indicate a problem with
 * the system. To view the alarms more clearly, you can go to the page that lists all the alarms and use the checkbox
 * labeled "Hide all AutoScaling alarms" to filter out the AutoScaling alarms. This will allow you to more easily
 * identify any alarms that may require attention.
 */

# If the average CPU utilization over a period of one minute falls below a certain threshold, the number of containers
# will be reduced (down to the minimum specified by ecs_autoscale_min_instances). This is done to minimize resource
# usage and cost when demand for the application is low. By continuously monitoring CPU utilization and adjusting the
# number of containers as needed, this autoscaling mechanism helps to ensure that the application can respond
# effectively to changes in traffic and workload, while also optimizing resource utilization.
variable "ecs_low_cpu_threshold_per" {
  default = "20"
}

# If the average CPU utilization over a period of one minute exceeds a certain threshold, the number of containers
# will be increased (up to the maximum specified by ecs_autoscale_max_instances). This is done in order to ensure that
# the application has sufficient capacity to handle the workload and maintain the desired level of performance.
# By continuously monitoring CPU utilization and adjusting the number of containers as needed, this autoscaling
# mechanism helps to ensure that the application can respond effectively to changes in traffic and workload.
variable "ecs_high_cpu_threshold_per" {
  default = "80"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name          = "${var.application}-${var.environment}-CPU-Utilization-High-${var.ecs_high_cpu_threshold_per}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.ecs_high_cpu_threshold_per

  dimensions = {
    ClusterName = aws_ecs_cluster.application.name
    ServiceName = aws_ecs_service.application.name
  }

  alarm_actions = [aws_appautoscaling_policy.app_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_utilization" {
  alarm_name          = "${var.application}-${var.environment}-CPU-Utilization-Low-${var.ecs_low_cpu_threshold_per}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.ecs_low_cpu_threshold_per

  dimensions = {
    ClusterName = aws_ecs_cluster.application.name
    ServiceName = aws_ecs_service.application.name
  }

  alarm_actions = [aws_appautoscaling_policy.app_scale_down.arn]
}

resource "aws_appautoscaling_policy" "app_scale_up" {
  name               = "app-scale-up"
  service_namespace  = aws_appautoscaling_target.app_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.app_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.app_scale_target.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "app_scale_down" {
  name               = "app-scale-down"
  service_namespace  = aws_appautoscaling_target.app_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.app_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.app_scale_target.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}
