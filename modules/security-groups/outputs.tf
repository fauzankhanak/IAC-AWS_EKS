output "cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = aws_security_group.cluster.id
}

output "node_group_security_group_id" {
  description = "ID of the EKS node group security group"
  value       = aws_security_group.node_group.id
}

output "load_balancer_security_group_id" {
  description = "ID of the load balancer security group"
  value       = aws_security_group.load_balancer.id
}

