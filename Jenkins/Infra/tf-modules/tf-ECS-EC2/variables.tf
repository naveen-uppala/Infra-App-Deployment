variable "aws_vpc" {
    description = "vpc id"
    type = string
}

variable "aws_subnet" {
    description = "aws subnets"
    type = list(string)
}

variable "image" {
    description = "Docker image to run in the ECS cluster"
    type = string
}
