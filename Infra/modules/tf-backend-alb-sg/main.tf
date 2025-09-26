resource "aws_security_group" "backend_alb_sg" {
  name        = "backend-alb-sg"
  description = "Security group for backend ALB allowing traffic only from ECS"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow traffic from ECS service"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [var.ecs_security_group_id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "backend-alb-sg"
  })
}
