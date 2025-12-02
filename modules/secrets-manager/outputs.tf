output "nexus_secret_arn" {
  description = "ARN of the Nexus registry secret in Secrets Manager"
  value       = aws_secretsmanager_secret.nexus_registry.arn
}

output "nexus_secret_name" {
  description = "Name of the Nexus registry secret"
  value       = aws_secretsmanager_secret.nexus_registry.name
}

output "nexus_secret_access_policy_arn" {
  description = "ARN of the IAM policy for accessing Nexus secret"
  value       = aws_iam_policy.nexus_secret_access.arn
}

