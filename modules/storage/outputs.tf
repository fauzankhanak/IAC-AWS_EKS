output "storage_class_name" {
  description = "Name of the default StorageClass"
  value       = kubernetes_storage_class.ebs.metadata[0].name
}

output "efs_storage_class_name" {
  description = "Name of the EFS StorageClass"
  value       = kubernetes_storage_class.efs.metadata[0].name
}

