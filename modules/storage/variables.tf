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

variable "storage_class_name" {
  description = "Name of the StorageClass"
  type        = string
  default     = "gp3"
}

variable "storage_class_type" {
  description = "Type of storage class (gp3, gp2, io1, etc.)"
  type        = string
  default     = "gp3"
}

variable "volume_binding_mode" {
  description = "Volume binding mode (Immediate or WaitForFirstConsumer)"
  type        = string
  default     = "WaitForFirstConsumer"
}

variable "reclaim_policy" {
  description = "Reclaim policy (Retain or Delete)"
  type        = string
  default     = "Delete"
}

variable "allow_volume_expansion" {
  description = "Allow volume expansion"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

