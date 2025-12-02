variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway for cost optimization (dev environments)"
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for S3 and EFS"
  type        = bool
  default     = true
}

variable "load_balancer_type" {
  description = "Type of load balancer: 'ALB' or 'NLB'"
  type        = string
  default     = "ALB"
  validation {
    condition     = contains(["ALB", "NLB"], var.load_balancer_type)
    error_message = "Load balancer type must be either 'ALB' or 'NLB'."
  }
}

variable "load_balancer_internal" {
  description = "Whether the load balancer is internal"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for load balancer"
  type        = bool
  default     = false
}

variable "ingress_node_port" {
  description = "NodePort for NGINX ingress controller"
  type        = number
  default     = 30001
}

variable "nexus_registry_url" {
  description = "URL of the Nexus registry"
  type        = string
}

variable "nexus_registry_secret_name" {
  description = "Name of the Kubernetes secret containing Nexus registry credentials"
  type        = string
  default     = "nexus-registry-secret"
}

variable "enable_ingress_ssl" {
  description = "Enable SSL/TLS for ingress"
  type        = bool
  default     = false
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

variable "node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    min_size      = number
    max_size      = number
    desired_size  = number
    disk_size     = number
    labels        = map(string)
    taints        = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = {
    general = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      min_size      = 2
      max_size      = 5
      desired_size  = 3
      disk_size     = 50
      labels        = {}
      taints        = []
    }
  }
}

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler"
  type        = bool
  default     = false
}

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts"
  type        = bool
  default     = true
}

variable "enable_kafka" {
  description = "Enable Kafka deployment"
  type        = bool
  default     = true
}

variable "enable_elk" {
  description = "Enable ELK stack deployment"
  type        = bool
  default     = true
}

variable "enable_prometheus" {
  description = "Enable Prometheus deployment"
  type        = bool
  default     = true
}

variable "enable_grafana" {
  description = "Enable Grafana deployment"
  type        = bool
  default     = true
}

variable "kafka_node_selector" {
  description = "Node selector for Kafka pods"
  type        = map(string)
  default     = {}
}

variable "elk_node_selector" {
  description = "Node selector for ELK stack pods"
  type        = map(string)
  default     = {}
}

variable "monitoring_node_selector" {
  description = "Node selector for monitoring pods (Prometheus/Grafana)"
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

