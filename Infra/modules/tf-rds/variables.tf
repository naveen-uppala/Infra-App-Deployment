variable "vpc_id" {
  type        = string
  description = "VPC ID where the RDS will be created"
}

variable "data_subnet_ids" {
  type        = list(string)
  description = "List of data-tier subnet IDs for RDS subnet group"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
}

variable "db_username" {
  type        = string
  description = "Master username for the RDS instance"
}

variable "db_password" {
  type        = string
  description = "Master password for the RDS instance"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Initial database name"
}

variable "db_instance_class" {
  type        = string
  default     = "db.t3.micro"
}

variable "eks_nodes_sg_id" {
  description = "Security group ID of EKS cluster & worker nodes"
  type        = string
}
