resource "aws_security_group" "this" {
  name_prefix = "${var.name}-alb-"
  description = "Application load balancer"
  vpc_id      = var.vpc_id

  # Replace without detaching: the new group exists before the old one is deleted
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each = var.ingress_cidrs

  security_group_id = aws_security_group.this.id
  description       = "HTTP from ${each.key}"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "targets" {
  security_group_id            = aws_security_group.this.id
  description                  = "To the targets"
  ip_protocol                  = "tcp"
  from_port                    = var.target_port
  to_port                      = var.target_port
  referenced_security_group_id = var.target_security_group_id
}

resource "aws_lb" "this" {
  name                       = var.name
  internal                   = var.internal
  load_balancer_type         = "application"
  subnets                    = var.subnet_ids
  security_groups            = [aws_security_group.this.id]
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix
    enabled = true
  }
}

resource "aws_lb_target_group" "this" {
  name                 = var.name
  port                 = var.target_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    path    = var.health_check_path
    matcher = var.health_check_matcher
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
