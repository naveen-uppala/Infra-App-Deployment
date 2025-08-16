variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN for the EKS cluster (IRSA)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (optional)"
  type        = string
  default     = null
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
