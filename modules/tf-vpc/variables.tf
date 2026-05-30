// modules/tf-vpc/variables.tf
variable "vpc_name" {
  description = "Name tag for the VPC."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR for the VPC (e.g., 192.168.0.0/16)."
  type        = string
}

variable "tags" {
  description = "Extra tags applied to all resources."
  type        = map(string)
  default     = {}
}
