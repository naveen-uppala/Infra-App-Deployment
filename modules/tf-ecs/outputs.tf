output "ecs_service_sg_id" {
  description = "Security group used by ECS tasks"
  value       = aws_security_group.ecs_service.id
}

output "subnet_ids" {
  value = var.subnet_ids
}
