# VPC Variables

variable "vpc_cidr" {
  type          = string
  description   = "VPC CIDR Block"
}

variable "web_tier_subnet_1_cidr" {
  type          = string
  description   = "Public Subnet 1 CIDR Block"
}

variable "web_tier_subnet_2_cidr" {
  type          = string
  description   = "Public Subnet 2 CIDR Block"
}

variable "web_tier_subnet_3_cidr" {
  type          = string
  description   = "Public Subnet 3 CIDR Block"
}

variable "app_tier_subnet_1_cidr" {
  type          = string
  description   = "Private Subnet 1 CIDR Block"
}

variable "app_tier_subnet_2_cidr" {
  type          = string
  description   = "Private Subnet 2 CIDR Block"
}

variable "app_tier_subnet_3_cidr" {
  type          = string
  description   = "Private Subnet 3 CIDR Block"
}

variable "data_tier_subnet_1_cidr" {
  type          = string
  description   = "Private Subnet 4 CIDR Block"
}

variable "data_tier_subnet_2_cidr" {
  type          = string
  description   = "Private Subnet 5 CIDR Block"
}

variable "data_tier_subnet_3_cidr" {
  type          = string
  description   = "Private Subnet 6 CIDR Block"
}
