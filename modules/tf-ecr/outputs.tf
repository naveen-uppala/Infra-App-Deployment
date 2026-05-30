output "repo_urls" {
  description = "Map repo_name => repository URL"
  value       = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}

output "repo_arns" {
  description = "Map repo_name => repository ARN"
  value       = { for k, r in aws_ecr_repository.this : k => r.arn }
}
