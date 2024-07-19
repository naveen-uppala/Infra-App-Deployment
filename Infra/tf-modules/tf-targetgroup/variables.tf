variable "container_port" {
type = number
    default = 8080
}

variable "targetgroup_name" {
type = string
    default = "<+serviceVariables.target_group_name>"
}
