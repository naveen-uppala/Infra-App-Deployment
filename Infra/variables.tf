variable "region" {
  description = "AWS region to deploy into (e.g., us-east-1)."
  type        = string
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
