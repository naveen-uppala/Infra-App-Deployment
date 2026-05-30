// modules/tf-rds/main.tf


# ------------------ Security Group ------------------

resource "aws_security_group" "rds_mysql_sg" {
  name        = "mysql-rds-sg"
  description = "Allow MySQL access only from EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow MySQL traffic from EKS worker nodes"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [var.eks_nodes_sg_id]   
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "mysql-rds-sg"
  })
}


# ------------------ Subnet Group ------------------

resource "aws_db_subnet_group" "mysql_subnet_group" {
  name       = "mysql-db-subnet-group"
  subnet_ids = var.data_subnet_ids

  tags = merge(var.tags, {
    Name = "mysql-db-subnet-group"
  })
}

# ------------------ RDS Instance ------------------

resource "aws_db_instance" "mysql" {
  identifier              = "mysql-rds-instance"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  storage_type            = "gp2"

  db_name                 = var.db_name
  username               = var.db_username
  password               = var.db_password
  port                   = 3306

  vpc_security_group_ids = [aws_security_group.rds_mysql_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.mysql_subnet_group.name

  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = merge(var.tags, {
    Name = "mysql-db-instance"
  })
}
