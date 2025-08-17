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


output "eks_cluster_endpoint" {
  value = module.tf-eks.tf_eks_cluster_endpoint
}
output "eks_cluster_ca_data" {
  value = module.tf-eks.tf_eks_cluster_ca_data
}

output "region" {
  value = var.region
}

output "eks_cluster_name" {
  value = module.tf-eks.tf_eks_cluster_name
}
