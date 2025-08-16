// Infra/main.tf
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws        = { source = "hashicorp/aws",       version = ">= 5.0" }
    kubernetes = { source = "hashicorp/kubernetes",version = ">= 2.27" }
    helm       = { source = "hashicorp/helm",      version = "~> 2.11.0" }
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
  cluster_name = var.eks_cluster_name
  eks_version  = var.eks_version
  vpc_id       = module.tf-vpc.vpc_id
  subnet_ids   = local.app_tier_subnet_ids
}

# Providers that connect to the newly created EKS cluster (no data sources)
provider "kubernetes" {
  alias                  = "eks"
  host                   = module.tf-eks.tf_eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.tf-eks.tf_eks_cluster_ca_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks", "get-token",
      "--region", var.region,
      "--cluster-name", module.tf-eks.eks_cluster_name
    ]
  }
}

provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = module.tf-eks.tf_eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.tf-eks.tf_eks_cluster_ca_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = [
        "eks", "get-token",
        "--region", var.region,
        "--cluster-name", module.tf-eks.eks_cluster_name
      ]
    }
  }
}

module "alb_controller" {
  source         = "./modules/tf-alb-controller"   # matches the files you sent
  cluster_name   = module.tf-eks.eks_cluster_name
  region         = var.region
  account_id     = var.account_id
  vpc_id         = module.tf-vpc.vpc_id
  controller_tag = var.controller_tag
  chart_version  = var.chart_version

  depends_on = [module.tf-eks]

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
    aws        = aws
  }
}

module "tf-ecr" {
  source           = "./modules/tf-ecr"
  repository_names = var.ecr_repository_names
  tags             = var.tags
}
