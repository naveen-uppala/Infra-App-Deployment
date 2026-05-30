variable "cluster_name" {
  description = "ECS Cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where services will run"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for ECS tasks/services (web-tier subnets)"
  type        = list(string)
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID of the frontend ALB allowed to talk to ECS services"
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "use_fargate_providers" {
  description = "Attach FARGATE and FARGATE_SPOT capacity providers with default strategy"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
