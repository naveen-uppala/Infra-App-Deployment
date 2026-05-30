// Infra/variables.tf

# Passing a value through Harness workspace varibales
variable "region" {
  description = "AWS region to deploy into (e.g., us-east-2)."
  type        = string
}

# Passing a value through Harness workspace varibales
variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g., 192.168.0.0/16)."
  type        = string
}

/*
# Passing a value through Harness workspace varibales
variable "account_id" {
  description = "AWS Account ID"
  type        = string
}
*/

variable "vpc_name" {
  description = "Name tag for the VPC."
  type        = string
  default     = "Cloud Nation Vpc"
}

variable "vpc_id" {
  description = "VPC ID (optional but recommended in some environments)"
  type        = string
  default     = null
}


variable "tags" {
  description = "Optional additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

