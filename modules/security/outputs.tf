output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}

output "security_hub_account_id" {
  description = "Account ID where Security Hub is enabled"
  value       = var.enable_security_hub ? data.aws_caller_identity.current.account_id : null
}

output "config_recorder_name" {
  description = "Name of the Config recorder"
  value       = var.enable_config ? aws_config_configuration_recorder.main[0].name : null
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
}

output "cloudtrail_s3_bucket" {
  description = "S3 bucket name for CloudTrail logs"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail[0].id : null
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].id : null
}

output "config_s3_bucket" {
  description = "S3 bucket name for Config snapshots"
  value       = var.enable_config ? aws_s3_bucket.config[0].id : null
}

