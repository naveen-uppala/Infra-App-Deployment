// Infra/outputs.tf
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

output "app_tier_subnet_ids" {
  value = [
    module.tf-vpc.private_subnet_ids["app-tier-subnet-1"],
    module.tf-vpc.private_subnet_ids["app-tier-subnet-2"],
    module.tf-vpc.private_subnet_ids["app-tier-subnet-3"],
  ]
}

output "alb_controller_irsa_role_arn" {
  value       = module.alb_controller.irsa_role_arn
  description = "IRSA role ARN used by the controller service account"
}

output "alb_controller_service_account" {
  value       = module.alb_controller.service_account
  description = "Namespace/name of the controller service account"
}
