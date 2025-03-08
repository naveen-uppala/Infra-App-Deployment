# --- ECS Cluster ---

resource "aws_ecs_cluster" "main" {
  name = "demo-cluster"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/demo"
  retention_in_days = 14
}