// modules/alb-controller/main.tf
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws        = { source = "hashicorp/aws",       version = ">= 5.0" }
    kubernetes = { source = "hashicorp/kubernetes",version = ">= 2.27" }
    helm       = { source = "hashicorp/helm",      version = "~> 2.11.0" }
    tls        = { source = "hashicorp/tls",       version = ">= 4.0" }
    http       = { source = "hashicorp/http",      version = ">= 3.4" }
  }
}

# Discover the cluster issuer URL from AWS
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

locals {
  issuer_url         = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  issuer_host_path   = replace(local.issuer_url, "https://", "")
  computed_oidc_arn  = "arn:aws:iam::${var.account_id}:oidc-provider/${local.issuer_host_path}"
  effective_oidc_arn = coalesce(var.cluster_oidc_provider_arn, local.computed_oidc_arn)
}

data "aws_iam_openid_connect_provider" "eks" {
  arn = local.effective_oidc_arn
}

data "http" "alb_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${var.controller_tag}/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb" {
  name        = "AWSLoadBalancerControllerIAMPolicy-${var.cluster_name}"
  description = "Policy for AWS Load Balancer Controller (${var.controller_tag})"
  policy      = data.http.alb_policy.response_body
}

locals {
  sa_namespace = "kube-system"
  sa_name      = "aws-load-balancer-controller"
  oidc_url     = replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")
}

resource "aws_iam_role" "alb_irsa" {
  name = "EKS-ALB-Controller-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Federated = data.aws_iam_openid_connect_provider.eks.arn },
      Action   = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${local.oidc_url}:sub" = "system:serviceaccount:${local.sa_namespace}:${local.sa_name}",
          "${local.oidc_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_irsa.name
  policy_arn = aws_iam_policy.alb.arn
}

resource "kubernetes_namespace" "kube_system" {
  metadata { name = local.sa_namespace }
}

resource "kubernetes_service_account" "alb" {
  metadata {
    name      = local.sa_name
    namespace = kubernetes_namespace.kube_system.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_irsa.arn
    }
    labels = { "app.kubernetes.io/name" = "aws-load-balancer-controller" }
  }
}

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = kubernetes_namespace.kube_system.metadata[0].name

  version    = var.chart_version != "" ? var.chart_version : null

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }


  dynamic "set" {
    for_each = var.vpc_id == null ? [] : [var.vpc_id]
    content {
      name  = "vpcId"
      value = set.value
    }
  }

  depends_on = [
    kubernetes_service_account.alb,
    aws_iam_role_policy_attachment.alb_attach
  ]
}
