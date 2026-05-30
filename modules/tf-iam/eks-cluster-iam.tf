# --- EKS Node Role ---
# Trust Policy document to Allows EKS to manage clusters on your behalf..
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Allows access to other AWS service resources that are required to operate clusters managed by EKS.
resource "aws_iam_role" "example" {
  name               = "eks-cluster-example"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]
}

output "eks_cluster_arn" {
  value = aws_iam_role.example.arn
}