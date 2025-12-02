# Application Load Balancer
resource "aws_lb" "alb" {
  count = var.lb_type == "ALB" ? 1 : 0

  name               = "${var.project_name}-${var.environment}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = null # Configure if needed
    enabled = false
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alb"
    }
  )
}

# Network Load Balancer
resource "aws_lb" "nlb" {
  count = var.lb_type == "NLB" ? 1 : 0

  name               = "${var.project_name}-${var.environment}-nlb"
  internal           = var.internal
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-nlb"
    }
  )
}

# Target Group for ALB (HTTP)
resource "aws_lb_target_group" "alb_http" {
  count = var.lb_type == "ALB" ? 1 : 0

  name     = "${var.project_name}-${var.environment}-alb-http-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/healthz"
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-http-tg"
    }
  )
}

# Target Group for ALB (HTTPS)
resource "aws_lb_target_group" "alb_https" {
  count = var.lb_type == "ALB" ? 1 : 0

  name     = "${var.project_name}-${var.environment}-alb-https-tg"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/healthz"
    protocol            = "HTTPS"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-https-tg"
    }
  )
}

# Target Group for NLB (TCP)
resource "aws_lb_target_group" "nlb_tcp" {
  count = var.lb_type == "NLB" ? 1 : 0

  name     = "${var.project_name}-${var.environment}-nlb-tcp-tg"
  port     = 30001
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
    protocol            = "TCP"
  }

  deregistration_delay = 30

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-nlb-tcp-tg"
    }
  )
}

# Listener for ALB (HTTP)
resource "aws_lb_listener" "alb_http" {
  count = var.lb_type == "ALB" ? 1 : 0

  load_balancer_arn = aws_lb.alb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_http[0].arn
  }
}

# Listener for ALB (HTTPS) - requires certificate
resource "aws_lb_listener" "alb_https" {
  count = var.lb_type == "ALB" ? 1 : 0

  load_balancer_arn = aws_lb.alb[0].arn
  port              = "443"
  protocol          = "HTTPS"
  # ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  # certificate_arn   = var.certificate_arn # Configure if needed

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_https[0].arn
  }
}

# Listener for NLB (TCP)
resource "aws_lb_listener" "nlb_tcp" {
  count = var.lb_type == "NLB" ? 1 : 0

  load_balancer_arn = aws_lb.nlb[0].arn
  port              = "30001"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tcp[0].arn
  }
}

