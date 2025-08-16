// modules/tf-vpc/main.tf
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnet = {
    name  = "Public-Subnet-1"
    index = 0
    az    = local.azs[0]
  }

  private_subnets = [
    { name = "web-tier-subnet-1",  index = 1, az = local.azs[0] },
    { name = "web-tier-subnet-2",  index = 2, az = local.azs[1] },
    { name = "web-tier-subnet-3",  index = 3, az = local.azs[2] },
    { name = "app-tier-subnet-1",  index = 4, az = local.azs[0] },
    { name = "app-tier-subnet-2",  index = 5, az = local.azs[1] },
    { name = "app-tier-subnet-3",  index = 6, az = local.azs[2] },
    { name = "data-tier-subnet-1", index = 7, az = local.azs[0] },
    { name = "data-tier-subnet-2", index = 8, az = local.azs[1] },
    { name = "data-tier-subnet-3", index = 9, az = local.azs[2] },
  ]

  private_subnets_by_name = { for s in local.private_subnets : s.name => s }

  common_tags = merge({ "Project" = "Cloud Nation" }, var.tags)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(local.common_tags, { "Name" = var.vpc_name })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { "Name" = "internet gateway" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  availability_zone       = local.public_subnet.az
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, local.public_subnet.index)
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {
    "Name" = local.public_subnet.name
    "Tier" = "public"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(local.common_tags, { "Name" = "Natgateway EIP" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags          = merge(local.common_tags, { "Name" = "Natgateway" })
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { "Name" = "public route table" })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets_by_name

  vpc_id            = aws_vpc.this.id
  availability_zone = each.value.az
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, each.value.index)

  tags = merge(local.common_tags, {
    "Name" = each.key
    "Tier" = "private"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { "Name" = "private route table" })
}

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
