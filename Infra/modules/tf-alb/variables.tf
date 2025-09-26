variable "vpc_id" {
  type        = string
  description = "VPC ID where the ALB will be created"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs where the ALB will be deployed"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
}

variable "alb_name" {
  type        = string
  default     = "frontend-alb"
  description = "Name of the Application Load Balancer"
}
