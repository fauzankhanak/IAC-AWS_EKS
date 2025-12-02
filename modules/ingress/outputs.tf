output "ingress_namespace" {
  description = "Namespace where NGINX ingress is deployed"
  value       = kubernetes_namespace.ingress.metadata[0].name
}

output "ingress_service_name" {
  description = "Name of the NGINX ingress service"
  value       = "ingress-nginx-controller"
}

output "node_port" {
  description = "NodePort used by NGINX ingress controller"
  value       = var.node_port
}

output "nexus_secret_name" {
  description = "Name of the Nexus registry secret"
  value       = var.nexus_registry_secret_name
}

