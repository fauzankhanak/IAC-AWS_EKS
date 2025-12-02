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

provider "helm" {
  kubernetes {
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
}

# Monitoring Namespace
resource "kubernetes_namespace" "monitoring" {
  count = (var.enable_prometheus || var.enable_grafana) ? 1 : 0

  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }
}

# Logging Namespace
resource "kubernetes_namespace" "logging" {
  count = var.enable_elk ? 1 : 0

  metadata {
    name = "logging"
    labels = {
      name = "logging"
    }
  }
}

# Kafka Namespace
resource "kubernetes_namespace" "kafka" {
  count = var.enable_kafka ? 1 : 0

  metadata {
    name = "kafka"
    labels = {
      name = "kafka"
    }
  }
}

# Nexus Registry Secret for workloads
resource "kubernetes_secret" "nexus_registry_monitoring" {
  count = (var.enable_prometheus || var.enable_grafana) ? 1 : 0

  metadata {
    name      = var.nexus_registry_secret_name
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.nexus_registry_url}" = {
          username = "nexus-user" # TODO: Replace with actual username from AWS Secrets Manager
          password = "nexus-password" # TODO: Replace with actual password from AWS Secrets Manager
          auth     = base64encode("nexus-user:nexus-password")
        }
      }
    })
  }

  # TODO: In production, use AWS Secrets Manager to retrieve credentials
}

resource "kubernetes_secret" "nexus_registry_logging" {
  count = var.enable_elk ? 1 : 0

  metadata {
    name      = var.nexus_registry_secret_name
    namespace = kubernetes_namespace.logging[0].metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.nexus_registry_url}" = {
          username = "nexus-user" # TODO: Replace with actual username from AWS Secrets Manager
          password = "nexus-password" # TODO: Replace with actual password from AWS Secrets Manager
          auth     = base64encode("nexus-user:nexus-password")
        }
      }
    })
  }

  # TODO: In production, use AWS Secrets Manager to retrieve credentials
}

resource "kubernetes_secret" "nexus_registry_kafka" {
  count = var.enable_kafka ? 1 : 0

  metadata {
    name      = var.nexus_registry_secret_name
    namespace = kubernetes_namespace.kafka[0].metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.nexus_registry_url}" = {
          username = "nexus-user" # TODO: Replace with actual username from AWS Secrets Manager
          password = "nexus-password" # TODO: Replace with actual password from AWS Secrets Manager
          auth     = base64encode("nexus-user:nexus-password")
        }
      }
    })
  }

  # TODO: In production, use AWS Secrets Manager to retrieve credentials
}

# Prometheus via Helm
resource "helm_release" "prometheus" {
  count = var.enable_prometheus ? 1 : 0

  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.0.0"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          nodeSelector = var.monitoring_node_selector
          resources = {
            requests = {
              cpu    = "500m"
              memory = "2Gi"
            }
            limits = {
              cpu    = "2000m"
              memory = "4Gi"
            }
          }
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
        }
      }
      alertmanager = {
        alertmanagerSpec = {
          nodeSelector = var.monitoring_node_selector
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }
      defaultRules = {
        create = true
      }
    })
  ]

  depends_on = [
    kubernetes_secret.nexus_registry_monitoring
  ]
}

# Grafana via Helm
resource "helm_release" "grafana" {
  count = var.enable_grafana ? 1 : 0

  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "7.0.19"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name

  values = [
    yamlencode({
      image = {
        repository = "${var.nexus_registry_url}/grafana/grafana"
        pullPolicy = "IfNotPresent"
      }
      imagePullSecrets = [
        {
          name = var.nexus_registry_secret_name
        }
      ]
      nodeSelector = var.monitoring_node_selector
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
      persistence = {
        enabled = true
        storageClassName = "gp3"
        size = "10Gi"
      }
      adminPassword = "admin" # Change this in production
    })
  ]

  depends_on = [
    kubernetes_secret.nexus_registry_monitoring
  ]
}

# Kafka via Helm (Bitnami Kafka)
resource "helm_release" "kafka" {
  count = var.enable_kafka ? 1 : 0

  name       = "kafka"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
  version    = "26.2.0"
  namespace  = kubernetes_namespace.kafka[0].metadata[0].name

  values = [
    yamlencode({
      replicaCount = 3
      persistence = {
        enabled = true
        storageClass = "gp3"
        size = "20Gi"
      }
      nodeSelector = var.kafka_node_selector
      resources = {
        requests = {
          cpu    = "500m"
          memory = "1Gi"
        }
        limits = {
          cpu    = "2000m"
          memory = "4Gi"
        }
      }
      zookeeper = {
        replicaCount = 3
        persistence = {
          enabled = true
          storageClass = "gp3"
          size = "10Gi"
        }
        resources = {
          requests = {
            cpu    = "250m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "1000m"
            memory = "2Gi"
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_secret.nexus_registry_kafka
  ]
}

# ELK Stack - Elasticsearch
resource "helm_release" "elasticsearch" {
  count = var.enable_elk ? 1 : 0

  name       = "elasticsearch"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  version    = "8.5.1"
  namespace  = kubernetes_namespace.logging[0].metadata[0].name

  values = [
    yamlencode({
      replicas = 3
      nodeSelector = var.elk_node_selector
      resources = {
        requests = {
          cpu    = "1000m"
          memory = "2Gi"
        }
        limits = {
          cpu    = "4000m"
          memory = "8Gi"
        }
      }
      volumeClaimTemplate = {
        accessModes = ["ReadWriteOnce"]
        storageClassName = "gp3"
        resources = {
          requests = {
            storage = "50Gi"
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_secret.nexus_registry_logging
  ]
}

# ELK Stack - Logstash
resource "helm_release" "logstash" {
  count = var.enable_elk ? 1 : 0

  name       = "logstash"
  repository = "https://helm.elastic.co"
  chart      = "logstash"
  version    = "8.5.1"
  namespace  = kubernetes_namespace.logging[0].metadata[0].name

  values = [
    yamlencode({
      replicas = 2
      nodeSelector = var.elk_node_selector
      resources = {
        requests = {
          cpu    = "500m"
          memory = "1Gi"
        }
        limits = {
          cpu    = "2000m"
          memory = "4Gi"
        }
      }
    })
  ]

  depends_on = [
    kubernetes_secret.nexus_registry_logging,
    helm_release.elasticsearch
  ]
}

# ELK Stack - Kibana
resource "helm_release" "kibana" {
  count = var.enable_elk ? 1 : 0

  name       = "kibana"
  repository = "https://helm.elastic.co"
  chart      = "kibana"
  version    = "8.5.1"
  namespace  = kubernetes_namespace.logging[0].metadata[0].name

  values = [
    yamlencode({
      replicas = 1
      nodeSelector = var.elk_node_selector
      resources = {
        requests = {
          cpu    = "500m"
          memory = "1Gi"
        }
        limits = {
          cpu    = "2000m"
          memory = "4Gi"
        }
      }
    })
  ]

  depends_on = [
    kubernetes_secret.nexus_registry_logging,
    helm_release.elasticsearch
  ]
}

