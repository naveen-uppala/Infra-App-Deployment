
# We already have providers wired from root.

# Discover the cluster issuer URL (e.g., https://oidc.eks.ap-south-1.amazonaws.com/id/XXXX)
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

locals {
  issuer_url        = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  issuer_host_path  = replace(local.issuer_url, "https://", "")   # oidc.eks.ap-south-1.amazonaws.com/id/XXXX
  computed_oidc_arn = "arn:aws:iam::${var.account_id}:oidc-provider/${local.issuer_host_path}"
  effective_oidc_arn = coalesce(var.cluster_oidc_provider_arn, local.computed_oidc_arn)
}

# Use the effective ARN (must already exist in the account — create once per cluster if needed)
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
      Action = "sts:AssumeRoleWithWebIdentity",
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

  # If var.chart_version == "", Helm provider prefers null (use latest)
  version    = var.chart_version != "" ? var.chart_version : null

  # Required values (each attribute on its own line)
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
    value = kubernetes_service_account.alb.metadata[0].name
  }

  # Recommended in some environments
  set {
    name  = "region"
    value = var.region
  }

  # Optional
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

