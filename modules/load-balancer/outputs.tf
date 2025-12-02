output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = var.lb_type == "ALB" ? aws_lb.alb[0].arn : aws_lb.nlb[0].arn
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = var.lb_type == "ALB" ? aws_lb.alb[0].dns_name : aws_lb.nlb[0].dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = var.lb_type == "ALB" ? aws_lb.alb[0].zone_id : aws_lb.nlb[0].zone_id
}

output "target_group_arns" {
  description = "ARNs of the target groups"
  value = var.lb_type == "ALB" ? [
    aws_lb_target_group.alb_http[0].arn,
    aws_lb_target_group.alb_https[0].arn
  ] : [aws_lb_target_group.nlb_tcp[0].arn]
}

output "target_group_http_arn" {
  description = "ARN of the HTTP target group (ALB only)"
  value       = var.lb_type == "ALB" ? aws_lb_target_group.alb_http[0].arn : null
}

output "target_group_https_arn" {
  description = "ARN of the HTTPS target group (ALB only)"
  value       = var.lb_type == "ALB" ? aws_lb_target_group.alb_https[0].arn : null
}

output "target_group_tcp_arn" {
  description = "ARN of the TCP target group (NLB only)"
  value       = var.lb_type == "NLB" ? aws_lb_target_group.nlb_tcp[0].arn : null
}

