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

# Token-based auth (no AWS CLI needed)
data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  alias                  = "eks"
  host                   = var.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(var.eks_cluster_ca_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = var.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(var.eks_cluster_ca_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

module "alb_controller" {
  source           = "../modules/alb-controller"

  eks_cluster_name = var.eks_cluster_name
  region           = var.region
  account_id       = var.account_id
  vpc_id           = var.vpc_id
  controller_tag   = var.controller_tag
  chart_version    = var.chart_version

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
    aws        = aws
  }
}
