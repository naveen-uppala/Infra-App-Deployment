// Infra/variables.tf
variable "region" {
  description = "AWS region to deploy into (e.g., us-east-1)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (optional but recommended in some environments)"
  type        = string
  default     = null
}

variable "vpc_name" {
  description = "Name tag for the VPC."
  type        = string
  default     = "Cloud Nation Vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g., 192.168.0.0/16)."
  type        = string
}

variable "tags" {
  description = "Optional additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "ecs_cluster_name" {
  description = "ECS Cluster name"
  type        = string
  default     = "cloud-nation-ecs"
}

variable "ecr_repository_names" {
  description = "List of ECR repo names to create"
  type        = list(string)
  default     = ["frontend", "customer", "driver"]
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "cloud-nation-eks"
}

variable "eks_version" {
  description = "EKS control plane version"
  type        = string
  default     = "1.29"
}

variable "controller_tag" {
  description = "Git tag for controller repo to fetch official IAM policy (e.g., v2.13.3). Use 'main' to track latest."
  type        = string
  default     = "v2.13.3"
}

variable "chart_version" {
  description = "Helm chart version for aws-load-balancer-controller (e.g., 1.13.4). Empty = latest."
  type        = string
  default     = "1.13.4"
}
