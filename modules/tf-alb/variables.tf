variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
}

variable "alb_name" {
  type        = string
  description = "Name of the ALB"
  default     = "frontend-alb"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate for HTTPS listener"
}
