variable "region"             { type = string }
variable "account_id"         { type = string }

# From Apply 1 outputs:
variable "eks_cluster_name"   { type = string }
variable "eks_cluster_endpoint" { type = string }
variable "eks_cluster_ca_data"  { type = string }

# Optional (but recommended to pass for Helm values)
variable "vpc_id"             { type = string }

# Keep your chart settings
variable "controller_tag" {
  type    = string
  default = "v2.13.3"
}
variable "chart_version" {
  type    = string
  default = "1.13.4"
}
