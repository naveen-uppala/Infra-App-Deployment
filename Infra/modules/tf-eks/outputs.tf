// modules/tf-eks/outputs.tf
output "tf_eks_cluster_name" {
  value = aws_eks_cluster.tf_eks_cluster.name
}
output "tf_eks_cluster_arn" {
  value = aws_eks_cluster.tf_eks_cluster.arn
}
output "tf_eks_cluster_security_group_id" {
  value = aws_security_group.tf_eks_cluster.id
}
output "tf_eks_node_group_name" {
  value = aws_eks_node_group.tf_eks_ng.node_group_name
}
# Used by root providers
output "tf_eks_cluster_endpoint" {
  value = aws_eks_cluster.tf_eks_cluster.endpoint
}
output "tf_eks_cluster_ca_data" {
  value = aws_eks_cluster.tf_eks_cluster.certificate_authority[0].data
}
