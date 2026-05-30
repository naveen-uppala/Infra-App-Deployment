output "waf_web_acl_arn" {
  description = "ARN of the created WAF WebACL"
  value       = aws_wafv2_web_acl.frontend_waf.arn
}
