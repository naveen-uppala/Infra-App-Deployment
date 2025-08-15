locals {
  common_tags = var.tags
}

# ECS cluster (note: cluster itself doesn't store subnets; services will use them)
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  dynamic "setting" {
    for_each = var.enable_container_insights ? [1] : []
    content {
      name  = "containerInsights"
      value = "enabled"
    }
  }

  tags = merge(local.common_tags, {
    Name = "ecs cluster"
  })
}

# Optional: set default capacity provider strategy for Fargate
resource "aws_ecs_cluster_capacity_providers" "fargate" {
  count              = var.use_fargate_providers ? 1 : 0
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 0
  }
}

# A security group for ECS services/tasks running in the web-tier subnets
# (egress-all by default; you can open ingress from an ALB SG later)
resource "aws_security_group" "ecs_service" {
  name        = "${var.cluster_name}-svc"
  description = "Security group for ECS services"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  tags = merge(local.common_tags, {
    Name = "ecs service sg"
  })
}

# (Optional example) default VPC endpoint interface SG rules could be added here later

# NOTE: We don't create services here, but we output the subnet list and SG so
# you can use them in aws_ecs_service with awsvpc networking.
