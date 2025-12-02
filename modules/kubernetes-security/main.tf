# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      var.cluster_name
    ]
  }
}

# Pod Security Standards Namespace Labels
resource "kubernetes_namespace" "with_pss" {
  for_each = var.enable_pod_security_standards ? {
    default           = "baseline"
    kube-system       = "privileged"
    kube-public       = "privileged"
    kube-node-lease   = "privileged"
    ingress-nginx     = var.pod_security_standard_level
    monitoring        = var.pod_security_standard_level
    logging           = var.pod_security_standard_level
    kafka             = var.pod_security_standard_level
  } : {}

  metadata {
    name = each.key
    labels = {
      "pod-security.kubernetes.io/enforce" = each.value
      "pod-security.kubernetes.io/audit"   = each.value
      "pod-security.kubernetes.io/warn"   = each.value
    }
  }
}

# Network Policy for default namespace (deny all by default)
resource "kubernetes_network_policy" "default_deny_all" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "default-deny-all"
    namespace = "default"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

# Network Policy for monitoring namespace
resource "kubernetes_network_policy" "monitoring" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "monitoring-network-policy"
    namespace = "monitoring"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "prometheus"
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
      ports {
        port     = "9090"
        protocol = "TCP"
      }
    }

    egress {
      to {
        namespace_selector {}
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
    }
  }
}

# Network Policy for logging namespace
resource "kubernetes_network_policy" "logging" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "logging-network-policy"
    namespace = "logging"
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        namespace_selector {}
      }
      ports {
        port     = "9200"
        protocol = "TCP"
      }
    }

    egress {
      to {
        namespace_selector {}
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
    }
  }
}

# Pod Disruption Budget for critical workloads
resource "kubernetes_pod_disruption_budget_v1" "prometheus" {
  count = var.enable_pod_security_standards ? 1 : 0

  metadata {
    name      = "prometheus-pdb"
    namespace = "monitoring"
  }

  spec {
    min_available = 1
    selector {
      match_labels = {
        app = "prometheus"
      }
    }
  }
}

# Security Context for default namespace
resource "kubernetes_limit_range_v1" "default" {
  count = var.enable_pod_security_standards ? 1 : 0

  metadata {
    name      = "default-limit-range"
    namespace = "default"
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "500m"
        memory = "512Mi"
      }
      default_request = {
        cpu    = "100m"
        memory = "128Mi"
      }
      max = {
        cpu    = "2"
        memory = "4Gi"
      }
    }
  }
}

# Resource Quota for default namespace
resource "kubernetes_resource_quota_v1" "default" {
  count = var.enable_pod_security_standards ? 1 : 0

  metadata {
    name      = "default-resource-quota"
    namespace = "default"
  }

  spec {
    hard = {
      requests.cpu    = "4"
      requests.memory = "8Gi"
      limits.cpu      = "8"
      limits.memory   = "16Gi"
      pods            = "10"
    }
  }
}

