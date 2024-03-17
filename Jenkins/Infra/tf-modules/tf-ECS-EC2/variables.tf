variable "aws_vpc" {
    description = "vpc id"
    type = string
}

variable "aws_subnet" {
    description = "aws subnets"
    type = list(string)
}

