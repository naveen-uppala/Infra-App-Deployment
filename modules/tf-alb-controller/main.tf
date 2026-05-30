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

# Get the EKS OIDC issuer URL
data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

# Fetch the TLS fingerprint for the issuer
data "tls_certificate" "oidc" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# CREATE the OIDC provider (one per cluster/account)
resource "aws_iam_openid_connect_provider" "eks" {
  url             = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}


data "http" "alb_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${var.controller_tag}/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb" {
  name        = "AWSLoadBalancerControllerIAMPolicy-${var.eks_cluster_name}"
  description = "Policy for AWS Load Balancer Controller (${var.controller_tag})"
  policy      = data.http.alb_policy.response_body
}

locals {
  sa_namespace = "kube-system"
  sa_name      = "aws-load-balancer-controller"
  oidc_url     = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}

resource "aws_iam_role" "alb_irsa" {
  name = "EKS-ALB-Controller-${var.eks_cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn } ,
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
    value = var.eks_cluster_name
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
