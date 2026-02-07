
// Infra/main.tf
terraform {

  backend "s3" {
    bucket         = "my-terraform-state-b25"
    key            = "envs/dev/network.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

  required_version = ">= 1.5.0"
  required_providers {
    aws        = { source = "hashicorp/aws",       version = ">= 5.0" }
    kubernetes = { source = "hashicorp/kubernetes",version = ">= 2.27" }
    helm       = { source = "hashicorp/helm",      version = "~> 2.11.0" }
    http  = { source = "hashicorp/http",  version = ">= 3.4.0" }
    tls   = { source = "hashicorp/tls",   version = ">= 4.0.0" }
  }
}

provider "aws" {
  region = var.region
}
module "tf_vpc" {
  source   = "../modules/tf-vpc"
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
  tags     = var.tags
}

# Pick the web/app-tier subnets from VPC outputs
locals {
  public_subnet_ids  = [
    module.tf_vpc.public_subnet_ids["Public-Subnet-1"],
    module.tf_vpc.public_subnet_ids["Public-Subnet-2"],
    module.tf_vpc.public_subnet_ids["Public-Subnet-3"],
  ]
  web_tier_subnet_ids = [
    module.tf_vpc.private_subnet_ids["web-tier-subnet-1"],
    module.tf_vpc.private_subnet_ids["web-tier-subnet-2"],
    module.tf_vpc.private_subnet_ids["web-tier-subnet-3"],
  ]
  app_tier_subnet_ids = [
    module.tf_vpc.private_subnet_ids["app-tier-subnet-1"],
    module.tf_vpc.private_subnet_ids["app-tier-subnet-2"],
    module.tf_vpc.private_subnet_ids["app-tier-subnet-3"],
  ]
  data_tier_subnet_ids = [
    module.tf_vpc.private_subnet_ids["data-tier-subnet-1"],
    module.tf_vpc.private_subnet_ids["data-tier-subnet-2"],
    module.tf_vpc.private_subnet_ids["data-tier-subnet-3"],
  ]

}

module "vpc_endpoints" {
  source = "../modules/tf-vpc-endpoints"
  vpc_id                   = module.tf_vpc.vpc_id
  private_route_table_id  = values(module.tf_vpc.private_route_table_id)
  private_subnet_ids       = values(module.tf_vpc.private_subnet_ids)
  region                   = var.region
  vpc_cidr                 = var.vpc_cidr
}
