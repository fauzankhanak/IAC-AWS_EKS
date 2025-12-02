variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_guardduty" {
  description = "Enable AWS GuardDuty for threat detection"
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Enable AWS Security Hub for security findings aggregation"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config for compliance monitoring"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable AWS CloudTrail for API logging"
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Enable AWS WAF for load balancer protection"
  type        = bool
  default     = true
}

variable "enable_inspector" {
  description = "Enable AWS Inspector for vulnerability assessment"
  type        = bool
  default     = true
}

variable "cloudtrail_s3_bucket" {
  description = "S3 bucket name for CloudTrail logs (will be created if not provided)"
  type        = string
  default     = ""
}

variable "config_s3_bucket" {
  description = "S3 bucket name for Config snapshots (will be created if not provided)"
  type        = string
  default     = ""
}

variable "waf_scope" {
  description = "Scope for WAF (CLOUDFRONT or REGIONAL)"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.waf_scope)
    error_message = "WAF scope must be either CLOUDFRONT or REGIONAL."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

