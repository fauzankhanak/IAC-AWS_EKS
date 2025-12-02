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

variable "nexus_registry_url" {
  description = "URL of the Nexus registry"
  type        = string
}

variable "nexus_registry_secret_name" {
  description = "Name of the Kubernetes secret containing Nexus registry credentials"
  type        = string
  default     = "nexus-registry-secret"
}

variable "enable_kafka" {
  description = "Enable Kafka deployment"
  type        = bool
  default     = true
}

variable "enable_elk" {
  description = "Enable ELK stack deployment"
  type        = bool
  default     = true
}

variable "enable_prometheus" {
  description = "Enable Prometheus deployment"
  type        = bool
  default     = true
}

variable "enable_grafana" {
  description = "Enable Grafana deployment"
  type        = bool
  default     = true
}

variable "kafka_node_selector" {
  description = "Node selector for Kafka pods"
  type        = map(string)
  default     = {}
}

variable "elk_node_selector" {
  description = "Node selector for ELK stack pods"
  type        = map(string)
  default     = {}
}

variable "monitoring_node_selector" {
  description = "Node selector for monitoring pods (Prometheus/Grafana)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

