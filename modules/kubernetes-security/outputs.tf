output "pod_security_standards_enabled" {
  description = "Whether Pod Security Standards are enabled"
  value       = var.enable_pod_security_standards
}

output "network_policies_enabled" {
  description = "Whether Network Policies are enabled"
  value       = var.enable_network_policies
}

