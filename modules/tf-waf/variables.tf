variable "alb_name" {
  description = "Name of the ALB (used for naming WAF)"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the ALB to associate the WAF with"
  type        = string
}
