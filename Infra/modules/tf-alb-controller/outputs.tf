output "irsa_role_arn" {
  value       = aws_iam_role.alb_irsa.arn
  description = "IRSA role ARN for the controller"
}

output "service_account" {
  value       = "${kubernetes_namespace.kube_system.metadata[0].name}/${kubernetes_service_account.alb.metadata[0].name}"
  description = "Controller ServiceAccount in namespace/name format"
}
