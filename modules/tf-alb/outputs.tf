output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.frontend_alb.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.frontend_alb.dns_name
}

output "alb_sg_id" {
  description = "Security group ID of the frontend ALB"
  value       = aws_security_group.alb_sg.id
}


output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.frontend_tg.arn
}
