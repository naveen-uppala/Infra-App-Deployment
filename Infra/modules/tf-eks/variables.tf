// modules/tf-eks/variables.tf
variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the cluster SG"
  type        = string
}

variable "subnet_ids" {
  description = "Exactly three private app-tier subnet IDs for control plane and node group"
  type        = list(string)
}

variable "backend_alb_sg_id" {
  description = "Security Group ID of the backend ALB that should be allowed to access EKS API"
  type        = string
}


variable "eks_version" {
  description = "EKS control plane version"
  type        = string
  default     = "1.29"
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}
