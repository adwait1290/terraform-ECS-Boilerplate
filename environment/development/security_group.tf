resource "aws_security_group" "security_group_lb" {
  name        = "${var.application}-${var.environment}-lb"
  description = "Allow connections from external resources while limiting connections from ${var.application}-${var.environment}-lb to internal resources"
  vpc_id      = var.vpc

  tags = var.tags
}

resource "aws_security_group" "security_group_task" {
  name        = "${var.application}-${var.environment}-task"
  description = "Limit connections from internal resources while allowing ${var.application}-${var.environment}-task to connect to all external resources"
  vpc_id      = var.vpc

  tags = var.tags
}

# Rules for the Load Balancer (Targets the task Security Group)
resource "aws_security_group_rule" "security_group_lb_egress_rule" {
  description              = "Only allow SG ${var.application}-${var.environment}-lb to connect to ${var.application}-${var.environment}-task on port ${var.container_port}"
  type                     = "egress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.security_group_task.id

  security_group_id = aws_security_group.security_group_lb.id
}

# Rules for the TASK (Targets the Load Balancer Security Group)
resource "aws_security_group_rule" "security_group_task_ingress_rule" {
  description              = "Only allow connections from SG ${var.application}-${var.environment}-lb on port ${var.container_port}"
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.security_group_lb.id

  security_group_id = aws_security_group.security_group_task.id
}

resource "aws_security_group_rule" "security_group_task_egress_rule" {
  description = "Allows task to establish connections to all resources"
  type        = "egress"
  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.security_group_task.id
}
