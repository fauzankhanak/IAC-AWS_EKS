variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64 encoded certificate data for the cluster"
  type        = string
}

variable "node_port" {
  description = "NodePort for NGINX ingress controller"
  type        = number
  default     = 30001
}

variable "nexus_registry_url" {
  description = "URL of the Nexus registry"
  type        = string
}

variable "nexus_registry_secret_name" {
  description = "Name of the Kubernetes secret containing Nexus registry credentials"
  type        = string
  default     = "nexus-registry-secret"
}

variable "enable_ssl" {
  description = "Enable SSL/TLS for ingress"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

