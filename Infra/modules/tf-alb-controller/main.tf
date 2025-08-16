# Child module: creates IAM policy+role (IRSA), k8s ServiceAccount, and Helm release


# --- Pull the official IAM policy from the controller repo (tagged for reproducibility) ---
data "http" "alb_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${var.controller_tag}/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb" {
  name        = "AWSLoadBalancerControllerIAMPolicy-${var.cluster_name}"
  description = "Policy for AWS Load Balancer Controller (${var.controller_tag})"
  policy      = data.http.alb_policy.response_body
}

# --- IRSA role bound to the controller ServiceAccount ---
data "aws_iam_openid_connect_provider" "eks" {
  arn = var.cluster_oidc_provider_arn
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

# --- K8s namespace & ServiceAccount with IRSA annotation ---
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

# --- Helm install of the controller chart ---
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = kubernetes_namespace.kube_system.metadata[0].name

  # Pin chart version (empty string will use the latest available)
  version    = var.chart_version

  # Required values
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

  # Recommended/sometimes required depending on environment
  set {
    name  = "region"
    value = var.region
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
