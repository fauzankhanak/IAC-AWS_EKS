variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lb_type" {
  description = "Type of load balancer: 'ALB' or 'NLB'"
  type        = string
  validation {
    condition     = contains(["ALB", "NLB"], var.lb_type)
    error_message = "Load balancer type must be either 'ALB' or 'NLB'."
  }
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the load balancer"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the load balancer"
  type        = list(string)
}

variable "internal" {
  description = "Whether the load balancer is internal"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

