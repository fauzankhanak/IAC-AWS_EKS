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

# Namespace for ingress
resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "ingress-nginx"
    labels = {
      name = "ingress-nginx"
    }
  }
}

# Nexus Registry Secret
resource "kubernetes_secret" "nexus_registry" {
  metadata {
    name      = var.nexus_registry_secret_name
    namespace = kubernetes_namespace.ingress.metadata[0].name
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

  # TODO: In production, use AWS Secrets Manager to retrieve credentials:
  # data "aws_secretsmanager_secret_version" "nexus" {
  #   secret_id = "nexus-registry-credentials"
  # }
  # Then decode and use the secret values
}

# NGINX Ingress Controller via Helm
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.3"
  namespace  = kubernetes_namespace.ingress.metadata[0].name

  values = [
    yamlencode({
      controller = {
        service = {
          type = "NodePort"
          nodePorts = {
            http  = var.node_port
            https = var.node_port + 1
          }
        }
        image = {
          repository = "${var.nexus_registry_url}/ingress-nginx/controller"
          pullPolicy = "IfNotPresent"
        }
        imagePullSecrets = [
          {
            name = var.nexus_registry_secret_name
          }
        ]
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
        metrics = {
          enabled = true
        }
        podSecurityPolicy = {
          enabled = false
        }
        admissionWebhooks = {
          enabled = false
        }
      }
    })
  ]

  depends_on = [
    kubernetes_secret.nexus_registry
  ]
}

# Service Account for NGINX Ingress (if IRSA is needed)
resource "kubernetes_service_account" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress-sa"
    namespace = kubernetes_namespace.ingress.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = "" # Configure if IRSA is needed
    }
  }
}

