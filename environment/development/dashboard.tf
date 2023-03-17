/**
 * This module sets up a CloudWatch dashboard for your application, which provides an overview of various metrics
 * related to the performance and resource usage of the app. The dashboard includes graphs that display the CPU and
 * memory utilization of the app, as well as HTTP-related metrics such as request count and response time. These
 * graphs can help you to monitor the health and performance of your app in real-time, identify trends and patterns,
 * and troubleshoot issues as they arise. The dashboard also allows you to customize the display and choose which
 * metrics to include, so you can focus on the most relevant information for your needs.
 *
 * On the CloudWatch dashboard created by this module, the graphs that display HTTP request metrics are stacked to
 * clearly show the status of the requests. Green is used to indicate successful hits, or HTTP response codes in the
 * 2xx range. Yellow is used for client errors, or HTTP response codes in the 4xx range, while red is used for server
 * errors, or HTTP response codes in the 5xx range. Stacking the graphs in this way allows you to quickly and easily
 * see the overall health and performance of the app at a glance, or even from a distance. When things are running
 * smoothly, the graphs will predominantly be green, making it easy to quickly check the dashboard for any issues.
 *
 * On the CloudWatch dashboard for your application, you will find two separate graphs that display the HTTP response
 * codes returned by your containers and your load balancer. In general, these two graphs will be similar, but there
 * are certain situations where they may differ. For instance, if your containers are taking longer than expected to
 * respond to requests, the load balancer may return a 504 Gateway Timeout error, even though the containers' graph
 * shows a 2xx response code. Similarly, if many of your containers are failing their health checks, the load balancer
 * may direct traffic to the healthy containers, causing the load balancer's graph to show a 2xx response code while
 * the containers' graph shows a 5xx error. Additionally, it is possible that the containers' graph may show more
 * traffic than the load balancer's graph, due to factors such as health checks and idempotent HTTP requests. These
 * graphs can be useful for understanding the performance and health of your app, and for identifying any issues that
 * may need to be addressed.
 */

resource "aws_cloudwatch_dashboard" "cloudwatch_dashboard" {
  dashboard_name = "${var.application}-${var.environment}-fargate"

  dashboard_body = <<EOF
{"widgets":[{"type":"metric","x":12,"y":6,"width":12,"height":6,"properties":{"view":"timeSeries","stacked":false,"metrics":[["AWS/ECS","MemoryUtilization","ServiceName","${var.application}-${var.environment}","ClusterName","${var.app}-${var.environment}",{"color":"#1f77b4"}],[".","CPUUtilization",".",".",".",".",{"color":"#9467bd"}]],"region":"${var.region}","period":300,"title":"Memory and CPU utilization","yAxis":{"left":{"min":0,"max":100}}}},{"type":"metric","x":0,"y":6,"width":12,"height":6,"properties":{"view":"timeSeries","stacked":true,"metrics":[["AWS/ApplicationELB","HTTPCode_Target_5XX_Count","TargetGroup","${aws_alb_target_group.main.arn_suffix}","LoadBalancer","${aws_alb.main.arn_suffix}",{"period":60,"color":"#d62728","stat":"Sum"}],[".","HTTPCode_Target_4XX_Count",".",".",".",".",{"period":60,"stat":"Sum","color":"#bcbd22"}],[".","HTTPCode_Target_3XX_Count",".",".",".",".",{"period":60,"stat":"Sum","color":"#98df8a"}],[".","HTTPCode_Target_2XX_Count",".",".",".",".",{"period":60,"stat":"Sum","color":"#2ca02c"}]],"region":"${var.region}","title":"Container responses","period":300,"yAxis":{"left":{"min":0}}}},{"type":"metric","x":12,"y":0,"width":12,"height":6,"properties":{"view":"timeSeries","stacked":false,"metrics":[["AWS/ApplicationELB","TargetResponseTime","LoadBalancer","${aws_alb.main.arn_suffix}",{"period":60,"stat":"p50"}],["...",{"period":60,"stat":"p90","color":"#c5b0d5"}],["...",{"period":60,"stat":"p99","color":"#dbdb8d"}]],"region":"${var.region}","period":300,"yAxis":{"left":{"min":0,"max":3}},"title":"Container response times"}},{"type":"metric","x":12,"y":12,"width":12,"height":2,"properties":{"view":"singleValue","metrics":[["AWS/ApplicationELB","HealthyHostCount","TargetGroup","${aws_alb_target_group.main.arn_suffix}","LoadBalancer","${aws_alb.main.arn_suffix}",{"color":"#2ca02c","period":60}],[".","UnHealthyHostCount",".",".",".",".",{"color":"#d62728","period":60}]],"region":"${var.region}","period":300,"stacked":false}},{"type":"metric","x":0,"y":0,"width":12,"height":6,"properties":{"view":"timeSeries","stacked":true,"metrics":[["AWS/ApplicationELB","HTTPCode_Target_5XX_Count","LoadBalancer","${aws_alb.main.arn_suffix}",{"period":60,"stat":"Sum","color":"#d62728"}],[".","HTTPCode_Target_4XX_Count",".",".",{"period":60,"stat":"Sum","color":"#bcbd22"}],[".","HTTPCode_Target_3XX_Count",".",".",{"period":60,"stat":"Sum","color":"#98df8a"}],[".","HTTPCode_Target_2XX_Count",".",".",{"period":60,"stat":"Sum","color":"#2ca02c"}]],"region":"${var.region}","title":"Load balancer responses","period":300,"yAxis":{"left":{"min":0}}}}]}
EOF
}
