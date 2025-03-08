variable "aws_vpc" {
    description = "vpc id"
    type = string
}

variable "aws_subnet" {
    description = "aws subnets"
    type = list(string)
}

variable "ecs_node_profile_name" {
    description = "ecs node profile role arn"
    type = string
}
