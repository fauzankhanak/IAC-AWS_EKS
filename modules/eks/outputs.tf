output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.eks[0].arn : null
}

output "node_groups" {
  description = "Map of node group details"
  value = {
    for k, v in aws_eks_node_group.main : k => {
      id         = v.id
      arn        = v.arn
      status     = v.status
      capacity_type = v.capacity_type
    }
  }
}

output "kms_key_id" {
  description = "KMS key ID used for EKS encryption"
  value       = aws_kms_key.eks.id
}

output "kms_key_arn" {
  description = "KMS key ARN used for EKS encryption"
  value       = aws_kms_key.eks.arn
}

