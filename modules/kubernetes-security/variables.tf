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

variable "enable_pod_security_standards" {
  description = "Enable Pod Security Standards"
  type        = bool
  default     = true
}

variable "pod_security_standard_level" {
  description = "Pod Security Standard level (restricted, baseline, privileged)"
  type        = string
  default     = "baseline"
  validation {
    condition     = contains(["restricted", "baseline", "privileged"], var.pod_security_standard_level)
    error_message = "Pod Security Standard level must be restricted, baseline, or privileged."
  }
}

variable "enable_network_policies" {
  description = "Enable Network Policies"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

