output "vpc_id" {
  value = module.tf-vpc.vpc_id
}

output "public_subnet_id" {
  value = module.tf-vpc.public_subnet_id
}

output "private_subnet_ids" {
  value = module.tf-vpc.private_subnet_ids
}

output "ecs_service_security_group_id" {
  value = module.tf-ecs.service_security_group_id
}

output "ecr_repo_urls" {
  description = "Map repo_name => repository URL"
  value       = module.tf-ecr.repo_urls
}

output "ecr_repo_arns" {
  description = "Map repo_name => repository ARN"
  value       = module.tf-ecr.repo_arns
}
