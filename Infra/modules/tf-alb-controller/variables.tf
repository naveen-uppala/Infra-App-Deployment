// modules/alb-controller/variables.tf
variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (optional)"
  type        = string
  default     = null
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "controller_tag" {
  description = "Git tag for controller repo used to fetch the IAM policy (e.g., v2.13.3). Use 'main' to track latest."
  type        = string
  default     = "v2.13.3"
}

variable "chart_version" {
  description = "Helm chart version (e.g., 1.13.4). Empty = latest from repo."
  type        = string
  default     = "1.13.4"
}
