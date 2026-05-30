output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_port" {
  description = "Port number for RDS"
  value       = aws_db_instance.mysql.port
}

output "rds_security_group_id" {
  description = "Security Group ID for RDS"
  value       = aws_security_group.rds_mysql_sg.id
}
