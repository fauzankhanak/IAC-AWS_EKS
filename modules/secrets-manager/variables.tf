variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "nexus_registry_url" {
  description = "URL of the Nexus registry"
  type        = string
}

variable "nexus_username" {
  description = "Username for Nexus registry (sensitive)"
  type        = string
  sensitive   = true
}

variable "nexus_password" {
  description = "Password for Nexus registry (sensitive)"
  type        = string
  sensitive   = true
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting secrets (optional, uses default if not provided)"
  type        = string
  default     = "alias/aws/secretsmanager"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

