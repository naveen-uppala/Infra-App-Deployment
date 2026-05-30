# --- ECS Node Role ---
# Trust Policy document to allow Allows EC2 instances to call AWS services on your behalf.
data "aws_iam_policy_document" "ecs_node_policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

#Default policy for the Amazon EC2 Role for Amazon EC2 Container Service
resource "aws_iam_role" "ecs_node_role" {
  name               = "ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_policy_doc.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"]
}

#Instance profile for ecs_node_role
resource "aws_iam_instance_profile" "ecs_node" {
  name_prefix = "demo-ecs-node-profile"
  path        = "/ecs/instance/"
  role        = aws_iam_role.ecs_node_role.name
}


# --- ECS Tasks Role ---
# Trust Policy document to allow ECS tasks to call AWS services on your behalf.
data "aws_iam_policy_document" "ecs_task_policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

#Provides access to other AWS service resources that are required to run Amazon ECS tasks
resource "aws_iam_role" "ecs_task_exec_role" {
  name               = "ecs-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_policy_doc.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

output "ecs_node_profile_name" {
  value = aws_iam_instance_profile.ecs_node.name
}