provider "aws" {
  region = "ap-south-2"
}

terraform {
    backend "s3" {
        bucket = "terraform-s3-tcn"
        key    = "tcn/terraform.tfstate"
        region     = "ap-south-2"
        dynamodb_table = "dynamodb-state-locking"
    }
}

module "iam_policies_roles" {
  source = "../tf-modules/tf-iam"
}

module "ecs_cluster" {
  depends_on=[module.iam_policies_roles]
  source = "../tf-modules/tf-ECS-EC2"
  ecs_node_profile_name = module.iam_policies_roles.ecs_node_profile_name
  aws_vpc = "vpc-0509fde9ba64692ea"
  aws_subnet = ["subnet-0a58f7bb36b69534a","subnet-0ca455ad1f587a812","subnet-0918669d0c271ee73"]
}

module "eks_cluster" {
  depends_on=[module.iam_policies_roles]
  cluster_role_arn = module.iam_policies_roles.eks_cluster_arn
  node_group_role_arn = module.iam_policies_roles.node_group_role_arn
  source = "../tf-modules/tf-k8s"
  subnet_ids = ["subnet-0a58f7bb36b69534a","subnet-0ca455ad1f587a812","subnet-0918669d0c271ee73"]
}

