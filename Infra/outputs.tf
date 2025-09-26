

// VPC Outputs

output "region" {
  value = var.region
}

output "vpc_id" {
  value = module.tf-vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.tf-vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.tf-vpc.private_subnet_ids
}

output "app_tier_subnet_ids" {
  value = [
    module.tf-vpc.private_subnet_ids["app-tier-subnet-1"],
    module.tf-vpc.private_subnet_ids["app-tier-subnet-2"],
    module.tf-vpc.private_subnet_ids["app-tier-subnet-3"],
  ]
}


// ECS Outputs


output "ecs_service_sg_id" {
  description = "Security group ID for ECS services"
  value       = module.tf-ecs.ecs_service_sg_id
}


// ECR Outputs 

output "ecr_repo_urls" {
  description = "Map repo_name => repository URL"
  value       = module.tf-ecr.repo_urls
}


output "ecr_repo_arns" {
  description = "Map repo_name => repository ARN"
  value       = module.tf-ecr.repo_arns
}


// EKS Outputs 

output "eks_control_plane_sg_id" {
  description = "Default EKS control plane security group ID created automatically by AWS"
  value       = module.tf-eks.tf_eks_cluster_security_group_id
}

output "eks_cluster_endpoint" {
  value = module.tf-eks.tf_eks_cluster_endpoint
}
output "eks_cluster_ca_data" {
  value = module.tf-eks.tf_eks_cluster_ca_data
}

output "eks_cluster_name" {
  value = module.tf-eks.tf_eks_cluster_name
}

// Frontend ALB Outputs 

output "alb_dns_name" {
  value = module.tf-alb.alb_dns_name
}

output "alb_sg_id" {
  description = "Security group ID of the frontend ALB"
  value       = module.tf-alb.alb_sg_id 
}
