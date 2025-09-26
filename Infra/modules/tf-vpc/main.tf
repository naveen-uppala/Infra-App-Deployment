// modules/tf-vpc/main.tf
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnets = [
    { name = "Public-Subnet-1",  index = 0, az = local.azs[0] },
    { name = "Public-Subnet-2",  index = 1, az = local.azs[1] },
    { name = "Public-Subnet-3",  index = 2, az = local.azs[2] },
  ]

  private_subnets = [
    { name = "web-tier-subnet-1",  index = 3, az = local.azs[0] },
    { name = "web-tier-subnet-2",  index = 4, az = local.azs[1] },
    { name = "web-tier-subnet-3",  index = 5, az = local.azs[2] },
    { name = "app-tier-subnet-1",  index = 6, az = local.azs[0] },
    { name = "app-tier-subnet-2",  index = 7, az = local.azs[1] },
    { name = "app-tier-subnet-3",  index = 8, az = local.azs[2] },
    { name = "data-tier-subnet-1", index = 9, az = local.azs[0] },
    { name = "data-tier-subnet-2", index = 10, az = local.azs[1] },
    { name = "data-tier-subnet-3", index = 11, az = local.azs[2] },
  ]

  public_subnets_by_name  = { for s in local.public_subnets : s.name => s }
  private_subnets_by_name = { for s in local.private_subnets : s.name => s }

  # Map AZ to public subnet name to help routing later
  public_subnet_by_az = { for s in local.public_subnets : s.az => s.name }

  common_tags = merge({ "Project" = "Cloud Nation" }, var.tags)
}

# ---------- VPC ----------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(local.common_tags, { "Name" = var.vpc_name })
}

# ---------- Default Secuirty Group ----------
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "default-sg"
  }
}

# ---------- IGW ----------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { "Name" = "internet gateway" })
}

# ---------- PUBLIC SUBNETS ----------
resource "aws_subnet" "public" {
  for_each = local.public_subnets_by_name

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.az
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, each.value.index)
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    "Name" = each.key
    "Tier" = "public"
  })
}

# ---------- NAT GATEWAYS ----------
# Create one EIP per public subnet
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags     = merge(local.common_tags, { "Name" = "Natgateway EIP-${each.key}" })
}

# Create one NAT GW per public subnet
resource "aws_nat_gateway" "nat" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  tags          = merge(local.common_tags, { "Name" = "Natgateway-${each.key}" })
  depends_on    = [aws_internet_gateway.igw]
}

# ---------- PUBLIC ROUTES ----------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { "Name" = "public route table" })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate ALL public subnets with public route table
resource "aws_route_table_association" "public_assoc" {
  for_each      = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ---------- PRIVATE SUBNETS ----------
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

# ---------- PRIVATE ROUTE TABLES ----------
# One route table per private subnet (best practice for per-AZ NAT)
resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { "Name" = "private route table - ${each.key}" })
}

# Add a default route per private subnet -> NAT in same AZ
resource "aws_route" "private_default" {
  for_each = aws_subnet.private

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"

  # Pick NAT GW in the same AZ
  nat_gateway_id = aws_nat_gateway.nat[
    local.public_subnet_by_az[each.value.availability_zone]
  ].id
}

# Associate each private subnet with its route table
resource "aws_route_table_association" "private_assoc" {
  for_each      = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
