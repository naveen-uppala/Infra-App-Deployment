// Infra/main.tf
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws        = { source = "hashicorp/aws",       version = ">= 5.0" }
    kubernetes = { source = "hashicorp/kubernetes",version = ">= 2.27" }
    helm       = { source = "hashicorp/helm",      version = "~> 2.11.0" }
    http  = { source = "hashicorp/http",  version = ">= 3.4.0" }
    tls   = { source = "hashicorp/tls",   version = ">= 4.0.0" }
  }
}

provider "aws" {
  region = var.region
}

module "tf-vpc" {
  source   = "./modules/tf-vpc"
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
  tags     = var.tags
}

# Pick the web/app-tier subnets from VPC outputs
locals {
  web_tier_subnet_ids = [
    module.tf-vpc.private_subnet_ids["web-tier-subnet-1"],
    module.tf-vpc.private_subnet_ids["web-tier-subnet-2"],
    module.tf-vpc.private_subnet_ids["web-tier-subnet-3"],
  ]
  app_tier_subnet_ids = [
    module.tf-vpc.private_subnet_ids["app-tier-subnet-1"],
    module.tf-vpc.private_subnet_ids["app-tier-subnet-2"],
    module.tf-vpc.private_subnet_ids["app-tier-subnet-3"],
  ]
}

module "tf-ecs" {
  source                    = "./modules/tf-ecs"
  cluster_name              = var.ecs_cluster_name
  vpc_id                    = module.tf-vpc.vpc_id
  subnet_ids                = local.web_tier_subnet_ids
  enable_container_insights = true
  use_fargate_providers     = true
  tags                      = var.tags
}

module "tf-eks" {
  source       = "./modules/tf-eks"
  eks_cluster_name = var.eks_cluster_name
  eks_version  = var.eks_version
  vpc_id       = module.tf-vpc.vpc_id
  subnet_ids   = local.app_tier_subnet_ids
}


module "tf-ecr" {
  source           = "./modules/tf-ecr"
  repository_names = var.ecr_repository_names
  tags             = var.tags
}
