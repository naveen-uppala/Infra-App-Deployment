// modules/tf-eks/main.tf
# Security group for the EKS control plane
resource "aws_security_group" "tf_eks_cluster" {
  name        = "${var.eks_cluster_name}-cluster-sg"
  description = "Security group for EKS control plane"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }
}

# IAM role for EKS control plane
resource "aws_iam_role" "tf_eks_cluster" {
  name = "${var.eks_cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "tf_eks_cluster_policy" {
  role       = aws_iam_role.tf_eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS cluster (private endpoint only)
resource "aws_eks_cluster" "tf_eks_cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.tf_eks_cluster.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [aws_security_group.tf_eks_cluster.id]
    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  depends_on = [aws_iam_role_policy_attachment.tf_eks_cluster_policy]
}

# Node group IAM role
resource "aws_iam_role" "tf_eks_node" {
  name = "${var.eks_cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "tf_eks_node_worker" {
  role       = aws_iam_role.tf_eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "tf_eks_node_ecr" {
  role       = aws_iam_role.tf_eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "tf_eks_node_cni" {
  role       = aws_iam_role.tf_eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Managed node group (SPOT; t3.medium/t2.medium)
resource "aws_eks_node_group" "tf_eks_ng" {
  cluster_name    = aws_eks_cluster.tf_eks_cluster.name
  node_group_name = "${var.eks_cluster_name}-ng"
  node_role_arn   = aws_iam_role.tf_eks_node.arn
  subnet_ids      = var.subnet_ids

  capacity_type  = "SPOT"
  instance_types = ["t3.medium", "t2.medium"]
  ami_type       = "AL2_x86_64"

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.tf_eks_node_worker,
    aws_iam_role_policy_attachment.tf_eks_node_ecr,
    aws_iam_role_policy_attachment.tf_eks_node_cni
  ]
}
