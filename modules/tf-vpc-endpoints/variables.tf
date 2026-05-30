variable "region" {
  description = "AWS region to deploy into (e.g., us-east-2)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (optional but recommended in some environments)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g., 192.168.0.0/16)."
  type        = string
}

variable "private_route_table_id" {
  description = "List of private route tables"
  type = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnets"
  type = list(string)
}
