output "monitoring_namespace" {
  description = "Namespace for monitoring stack"
  value       = var.enable_prometheus || var.enable_grafana ? kubernetes_namespace.monitoring[0].metadata[0].name : null
}

output "logging_namespace" {
  description = "Namespace for logging stack"
  value       = var.enable_elk ? kubernetes_namespace.logging[0].metadata[0].name : null
}

output "kafka_namespace" {
  description = "Namespace for Kafka"
  value       = var.enable_kafka ? kubernetes_namespace.kafka[0].metadata[0].name : null
}

output "prometheus_release_name" {
  description = "Name of the Prometheus Helm release"
  value       = var.enable_prometheus ? helm_release.prometheus[0].name : null
}

output "grafana_release_name" {
  description = "Name of the Grafana Helm release"
  value       = var.enable_grafana ? helm_release.grafana[0].name : null
}

output "kafka_release_name" {
  description = "Name of the Kafka Helm release"
  value       = var.enable_kafka ? helm_release.kafka[0].name : null
}

