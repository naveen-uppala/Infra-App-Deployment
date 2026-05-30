###############################################
# IAM Role for EKS Control Plane
###############################################
resource "aws_iam_role" "tf_eks_cluster" {
  name = "${var.eks_cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "tf_eks_cluster_policy" {
  role       = aws_iam_role.tf_eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Required for Auto Mode — allows EKS to provision and manage nodes automatically
resource "aws_iam_role_policy_attachment" "tf_eks_compute_policy" {
  role       = aws_iam_role.tf_eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
}

# Required for Auto Mode — allows EKS to manage load balancers and networking
resource "aws_iam_role_policy_attachment" "tf_eks_block_storage_policy" {
  role       = aws_iam_role.tf_eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
}

resource "aws_iam_role_policy_attachment" "tf_eks_load_balancing_policy" {
  role       = aws_iam_role.tf_eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
}

resource "aws_iam_role_policy_attachment" "tf_eks_networking_policy" {
  role       = aws_iam_role.tf_eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
}

###############################################
# EKS Cluster - Auto Mode
###############################################
resource "aws_eks_cluster" "tf_eks_cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.tf_eks_cluster.arn
  version  = var.eks_version
  bootstrap_self_managed_addons = false

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  access_config {
    authentication_mode = "API"
  }

  # Enable Auto Mode — EKS fully manages node provisioning
  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "system"]
    node_role_arn = aws_iam_role.tf_eks_auto_node.arn
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.tf_eks_cluster_policy,
    aws_iam_role_policy_attachment.tf_eks_compute_policy,
    aws_iam_role_policy_attachment.tf_eks_block_storage_policy,
    aws_iam_role_policy_attachment.tf_eks_load_balancing_policy,
    aws_iam_role_policy_attachment.tf_eks_networking_policy,
  ]
}

###############################################
# Tag the Default EKS Security Group
###############################################
resource "aws_ec2_tag" "eks_default_sg_name" {
  resource_id = aws_eks_cluster.tf_eks_cluster.vpc_config[0].cluster_security_group_id
  key         = "Name"
  value       = "${var.eks_cluster_name}-cluster-sg"
  depends_on  = [aws_eks_cluster.tf_eks_cluster]
}

# Allow HTTPS traffic from Backend ALB to EKS control plane
resource "aws_security_group_rule" "allow_backend_alb_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.backend_alb_sg_id
  security_group_id        = aws_eks_cluster.tf_eks_cluster.vpc_config[0].cluster_security_group_id
  description              = "Allow HTTPS traffic from backend ALB to EKS control plane"
  depends_on               = [aws_eks_cluster.tf_eks_cluster]
}

###############################################
# IAM Role for Auto Mode Nodes
# (used by compute_config.node_role_arn above)
###############################################
resource "aws_iam_role" "tf_eks_auto_node" {
  name = "${var.eks_cluster_name}-auto-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "tf_eks_auto_node_worker" {
  role       = aws_iam_role.tf_eks_auto_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
}

resource "aws_iam_role_policy_attachment" "tf_eks_auto_node_ecr" {
  role       = aws_iam_role.tf_eks_auto_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}
