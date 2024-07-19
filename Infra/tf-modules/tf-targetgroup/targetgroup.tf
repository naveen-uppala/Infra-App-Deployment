provider "aws" {
   region = "<+serviceVariables.region>"
}

resource "aws_lb_target_group" "ecs-alb-target-group" {
  name        = "<+serviceVariables.target_group_name>"
  port        = "<+serviceVariables.containerport>"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "<+serviceVariables.VpcId"
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
  listener_arn = "<+serviceVariables.containerport>"
  priority     = "<+serviceVariables.PriorityNumber>"

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs-alb-target-group.arn
  }

  condition {
    path_pattern {
      values = ["<+pipeline.variables.AppName>*"]
    }
  }
}
