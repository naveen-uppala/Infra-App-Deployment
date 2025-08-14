output "vpc_id" {
  value = module.tf-vpc.vpc_id
}

output "public_subnet_id" {
  value = module.tf-vpc.public_subnet_id
}

output "private_subnet_ids" {
  value = module.tf-vpc.private_subnet_ids
}

output "internet_gateway_id" {
  value = module.tf-vpc.internet_gateway_id
}

output "nat_gateway_id" {
  value = module.tf-vpc.nat_gateway_id
}

output "public_route_table_id" {
  value = module.tf-vpc.public_route_table_id
}

output "private_route_table_id" {
  value = module.tf-vpc.private_route_table_id
}
