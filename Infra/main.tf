terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
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

# Pick the 3 web-tier subnets from the VPC outputs
locals {
  web_tier_subnet_ids = [
    module.tf-vpc.private_subnet_ids["web-tier-subnet-1"],
    module.tf-vpc.private_subnet_ids["web-tier-subnet-2"],
    module.tf-vpc.private_subnet_ids["web-tier-subnet-3"],
  ]
}

# --- New ECS module ---
module "tf-ecs" {
  source                    = "./modules/tf-ecs"
  cluster_name              = var.ecs_cluster_name
  vpc_id                    = module.tf-vpc.vpc_id
  subnet_ids                = local.web_tier_subnet_ids
  enable_container_insights = true
  use_fargate_providers     = true
  tags                      = var.tags
}

module "ecr" {
  source              = "./modules/tf-ecr"
  repository_names    = var.ecr_repository_names
  tags                = var.tags
}
