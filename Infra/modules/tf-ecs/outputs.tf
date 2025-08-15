output "service_security_group_id" {
  value = aws_security_group.ecs_service.id
}

output "subnet_ids" {
  value = var.subnet_ids
}
