variable "vpc_id" {
  type        = string
  description = "VPC ID where the ALB SG will be created"
}

variable "ecs_security_group_id" {
  type        = string
  description = "Security Group ID of the ECS cluster/service tasks"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
}
