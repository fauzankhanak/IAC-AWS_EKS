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

# StorageClass for EBS volumes
resource "kubernetes_storage_class" "ebs" {
  metadata {
    name = var.storage_class_name
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = var.volume_binding_mode
  reclaim_policy         = var.reclaim_policy
  allow_volume_expansion = var.allow_volume_expansion

  parameters = {
    type      = var.storage_class_type
    encrypted = "true"
    fsType    = "ext4"
  }
}

# StorageClass for EFS (if needed)
resource "kubernetes_storage_class" "efs" {
  metadata {
    name = "efs-sc"
  }

  storage_provisioner = "efs.csi.aws.com"
  volume_binding_mode = "Immediate"
  reclaim_policy      = "Retain"

  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = "" # Set this if EFS file system is created
    directoryPerms   = "0755"
  }
}

