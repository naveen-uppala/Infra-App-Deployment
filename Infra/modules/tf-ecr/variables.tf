variable "repository_names" {
  description = "ECR repositories to create"
  type        = list(string)
}

variable "tags" {
  type        = map(string)
  default     = {}
}
