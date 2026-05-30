resource "aws_iam_role" "node_group_role" {
  name = "eks-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  
  managed_policy_arns =  ["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", 
  "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy", 
  "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]
}

output "node_group_role_arn" {
  value = aws_iam_role.node_group_role.arn
}