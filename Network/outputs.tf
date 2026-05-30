

// VPC Outputs

output "region" {
  value = var.region
}

output "vpc_id" {
  description = "VPC ID — consumed by Infra layer via remote state"
  value       = module.tf_vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.tf_vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of 3 public subnet IDs"
  value = [
    module.tf_vpc.public_subnet_ids["Public-Subnet-1"],
    module.tf_vpc.public_subnet_ids["Public-Subnet-2"],
    module.tf_vpc.public_subnet_ids["Public-Subnet-3"],
  ]
}

output "web_tier_subnet_ids" {
  description = "List of 3 web-tier private subnet IDs"
  value = [
    module.tf_vpc.private_subnet_ids["web-tier-subnet-1"],
    module.tf_vpc.private_subnet_ids["web-tier-subnet-2"],
    module.tf_vpc.private_subnet_ids["web-tier-subnet-3"],
  ]
}

output "app_tier_subnet_ids" {
  description = "List of 3 app-tier private subnet IDs"
  value = [
    module.tf_vpc.private_subnet_ids["app-tier-subnet-1"],
    module.tf_vpc.private_subnet_ids["app-tier-subnet-2"],
    module.tf_vpc.private_subnet_ids["app-tier-subnet-3"],
  ]
}

output "data_tier_subnet_ids" {
  description = "List of 3 data-tier private subnet IDs"
  value = [
    module.tf_vpc.private_subnet_ids["data-tier-subnet-1"],
    module.tf_vpc.private_subnet_ids["data-tier-subnet-2"],
    module.tf_vpc.private_subnet_ids["data-tier-subnet-3"],
  ]
}

