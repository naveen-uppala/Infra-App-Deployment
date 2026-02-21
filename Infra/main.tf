// Infra/main.tf
terraform {

  backend "s3" {
    bucket         = "my-terraform-state-b25"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

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
module "tf_vpc" {
  source   = "./modules/tf-vpc"
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
  tags     = var.tags
}

# Pick the web/app-tier subnets from VPC outputs
locals {
  public_subnet_ids  = [
    module.tf_vpc.public_subnet_ids["Public-Subnet-1"],
    module.tf_vpc.public_subnet_ids["Public-Subnet-2"],
    module.tf_vpc.public_subnet_ids["Public-Subnet-3"],
  ]
  web_tier_subnet_ids = [
    module.tf_vpc.private_subnet_ids["web-tier-subnet-1"],
    module.tf_vpc.private_subnet_ids["web-tier-subnet-2"],
    module.tf_vpc.private_subnet_ids["web-tier-subnet-3"],
  ]
  app_tier_subnet_ids = [
    module.tf_vpc.private_subnet_ids["app-tier-subnet-1"],
    module.tf_vpc.private_subnet_ids["app-tier-subnet-2"],
    module.tf_vpc.private_subnet_ids["app-tier-subnet-3"],
  ]
  data_tier_subnet_ids = [
    module.tf_vpc.private_subnet_ids["data-tier-subnet-1"],
    module.tf_vpc.private_subnet_ids["data-tier-subnet-2"],
    module.tf_vpc.private_subnet_ids["data-tier-subnet-3"],
  ]

}


module "tf_alb" {
  source             = "./modules/tf-alb"
  vpc_id             = module.tf_vpc.vpc_id
  public_subnet_ids  = local.public_subnet_ids
  alb_name           = "frontend-alb"
  acm_certificate_arn = var.acm_certificate_arn  
  tags               = var.tags
}


module "tf_ecr" {
  source           = "./modules/tf-ecr"
  repository_names = var.ecr_repository_names
  tags             = var.tags
}




module "tf_ecs" {
  source                    = "./modules/tf-ecs"
  cluster_name              = var.ecs_cluster_name
  alb_security_group_id     = module.tf_alb.alb_sg_id
  vpc_id                    = module.tf_vpc.vpc_id
  subnet_ids                = local.web_tier_subnet_ids
  enable_container_insights = true
  use_fargate_providers     = true
  tags                      = var.tags
}

module "backend_alb_sg" {
  source                = "./modules/tf-backend-alb-sg"
  vpc_id               = module.tf_vpc.vpc_id
  ecs_security_group_id = module.tf_ecs.ecs_service_sg_id
  tags                 = var.tags
}


module "tf_eks" {
  source       = "./modules/tf-eks"
  eks_cluster_name = var.eks_cluster_name
  eks_version  = var.eks_version
  vpc_id       = module.tf_vpc.vpc_id
  subnet_ids   = local.app_tier_subnet_ids
  backend_alb_sg_id     = module.backend_alb_sg.backend_alb_sg_id 
  tags               = var.tags  
  depends_on = [module.vpc_endpoints]

}


module "tf_rds" {
  source          = "./modules/tf-rds"
  vpc_id          = module.tf_vpc.vpc_id
  eks_nodes_sg_id  = module.tf_eks.tf_eks_cluster_security_group_id
  data_subnet_ids = local.data_tier_subnet_ids
  db_username     = var.db_username
  db_password     = var.db_password
  db_name         = var.db_name
  db_instance_class = var.db_instance_class
  tags = var.tags
}
