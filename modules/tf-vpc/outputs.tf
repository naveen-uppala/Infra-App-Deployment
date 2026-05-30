// modules/tf-vpc/outputs.tf


output "vpc_id" {
  value = aws_vpc.this.id
}


output "private_subnet_ids" {
  value = { for k, s in aws_subnet.private : k => s.id }
}


output "public_subnet_ids" {
  value = { for k, s in aws_subnet.public : k => s.id }
}


output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}


output "nat_gateway_id" {
  value = { for k, n in aws_nat_gateway.nat : k => n.id }
}


output "public_route_table_id" {
  value = aws_route_table.public.id
}


output "private_route_table_id" {
  value = { for k, rt in aws_route_table.private : k => rt.id }
}
