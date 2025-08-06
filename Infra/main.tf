provider "aws" {
  region = "us-east-2"
}

# terraform {
#     backend "s3" {
#         bucket = "terraform-s3-tcn"
#         key    = "tcn/terraform.tfstate"
#         region     = "us-east-2"
#         dynamodb_table = "dynamodb-state-locking"
#     }
# }

 module "aws_sg" {
   source = "./modules/tf-sg"

   # Forward root input to child module
   vpc_id  = var.vpc_id
 }


#  module "iam_policies_roles" {
#    source = "../tf-modules/tf-iam"
#  }


#  module "ecs_cluster" {
#    depends_on=[module.iam_policies_roles]
#    source = "../tf-modules/tf-ECS-FARGATE"
#    ecs_node_profile_name = module.iam_policies_roles.ecs_node_profile_name
#    aws_vpc = "vpc-00383e29bb7567ac7"
#    aws_subnet = ["subnet-0a2aebbdf06fc888b","subnet-0073844bcbf183fd0","subnet-0aa476740e263c06b"]
#  }

/*
module "eks_cluster" {
  depends_on=[module.iam_policies_roles]
  cluster_role_arn = module.iam_policies_roles.eks_cluster_arn
  node_group_role_arn = module.iam_policies_roles.node_group_role_arn
  source = "../tf-modules/tf-k8s"
  subnet_ids = ["subnet-0a58f7bb36b69534a","subnet-0ca455ad1f587a812","subnet-0918669d0c271ee73"]
}
*/
