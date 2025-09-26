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

# Passing a value through Harness workspace varibales
variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

# Passing a value through Harness workspace varibales
variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
}

# Passing a value through Harness workspace varibales
variable "db_password" {
  description = "Master password for the RDS instance"
  type        = string
  sensitive   = true
}

# Passing a value through Harness workspace varibales
variable "db_name" {
  description = "Initial database name"
  type        = string
}

# Passing a value through Harness workspace varibales
variable "acm_certificate_arn" {
  type        = string
  description = "ARN of the ACM SSL certificate for the ALB HTTPS listener"
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

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

variable "ecs_cluster_name" {
  description = "ECS Cluster name"
  type        = string
  default     = "cloud-nation-ecs"
}

variable "ecr_repository_names" {
  description = "List of ECR repo names to create"
  type        = list(string)
  default     = ["frontend", "customer", "driver"]
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "cloud-nation-eks"
}


variable "eks_version" {
  description = "EKS control plane version"
  type        = string
  default     = "1.29"
}

variable "controller_tag" {
  description = "Git tag for controller repo to fetch official IAM policy (e.g., v2.13.3). Use 'main' to track latest."
  type        = string
  default     = "v2.13.3"
}

variable "chart_version" {
  description = "Helm chart version for aws-load-balancer-controller (e.g., 1.13.4). Empty = latest."
  type        = string
  default     = "1.13.4"
}
