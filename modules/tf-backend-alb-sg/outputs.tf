output "backend_alb_sg_id" {
  description = "ID of the backend ALB security group"
  value       = aws_security_group.backend_alb_sg.id
}
