provider "aws" {
   region = "<+serviceVariables.region>"
}

resource "aws_lb_target_group" "ecs-alb-target-group" {
  name        = var.container_port
  port        = var.targetgroup_name
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.VpcId
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
  listener_arn = var.listenerArn
  priority     = var.priorityNumber

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs-alb-target-group.arn
  }

  condition {
    path_pattern {
      values = ["var.pathName"]
    }
  }
}
