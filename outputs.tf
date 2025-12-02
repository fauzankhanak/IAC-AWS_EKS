# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# EKS Outputs
output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

# Load Balancer Outputs
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.load_balancer.load_balancer_dns_name
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = module.load_balancer.load_balancer_arn
}

# Storage Outputs
output "storage_class_name" {
  description = "Name of the default StorageClass"
  value       = module.storage.storage_class_name
}

# Ingress Outputs
output "ingress_namespace" {
  description = "Namespace where NGINX ingress is deployed"
  value       = module.ingress.ingress_namespace
}

output "ingress_node_port" {
  description = "NodePort used by NGINX ingress controller"
  value       = module.ingress.node_port
}

# Workloads Outputs
output "monitoring_namespace" {
  description = "Namespace for monitoring stack"
  value       = module.workloads.monitoring_namespace
}

output "logging_namespace" {
  description = "Namespace for logging stack"
  value       = module.workloads.logging_namespace
}

output "kafka_namespace" {
  description = "Namespace for Kafka"
  value       = module.workloads.kafka_namespace
}

# IAM Outputs
output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = module.iam.cluster_role_arn
}

output "node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = module.iam.node_group_role_arn
}

# Security Outputs
output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = module.security.guardduty_detector_id
}

output "security_hub_account_id" {
  description = "Account ID where Security Hub is enabled"
  value       = module.security.security_hub_account_id
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = module.security.cloudtrail_arn
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = module.security.waf_web_acl_arn
}

output "config_recorder_name" {
  description = "Name of the Config recorder"
  value       = module.security.config_recorder_name
}

output "nexus_secret_arn" {
  description = "ARN of the Nexus registry secret in Secrets Manager"
  value       = module.secrets_manager.nexus_secret_arn
  sensitive   = true
}

