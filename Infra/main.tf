terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws =         { source  = "hashicorp/aws", version = ">= 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.27" }
    helm  =      { source = "hashicorp/helm",       version = ">= 2.11" }
  }
}

# Look up the EKS cluster to wire up k8s/helm providers
data "aws_eks_cluster" "this" { name = var.cluster_name }
data "aws_eks_cluster_auth" "this" { name = var.cluster_name }

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}


# Pick the 3 web-tier subnets from the VPC outputs
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

module "tf-vpc" {
  source   = "./modules/tf-vpc"

  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
  tags     = var.tags
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
  source       = "./modules/tf-eks"    # path to the module folder below

  cluster_name  = var.eks_cluster_name
  eks_version   = var.eks_version
  vpc_id        = module.tf-vpc.vpc_id
  subnet_ids    = local.app_tier_subnet_ids
}


module "alb_controller" {
  source   = "./modules/tf-alb-controller"

  cluster_name   = var.cluster_name
  region         = var.region
  account_id     = var.account_id
  vpc_id         = var.vpc_id
  controller_tag = var.controller_tag
  chart_version  = var.chart_version
}

module "tf-ecr" {
  source              = "./modules/tf-ecr"

  repository_names    = var.ecr_repository_names
  tags                = var.tags
}
