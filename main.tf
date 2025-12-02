# Provider Configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.common_tags,
      {
        Project     = var.project_name
        Environment = var.environment
        ManagedBy   = "Terraform"
      }
    )
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name     = var.project_name
  environment      = var.environment
  region           = var.aws_region
  vpc_cidr         = var.vpc_cidr
  availability_zones = var.availability_zones
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway  = var.single_nat_gateway
  enable_vpc_endpoints = var.enable_vpc_endpoints
  tags             = var.common_tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = var.cluster_name
  tags         = var.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr
  tags         = var.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  project_name                  = var.project_name
  environment                   = var.environment
  cluster_name                  = var.cluster_name
  cluster_version               = var.cluster_version
  cluster_role_arn             = module.iam.cluster_role_arn
  node_group_role_arn          = module.iam.node_group_role_arn
  vpc_id                        = module.vpc.vpc_id
  subnet_ids                    = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)
  cluster_security_group_id     = module.security_groups.cluster_security_group_id
  node_group_security_group_id  = module.security_groups.node_group_security_group_id
  node_groups                   = var.node_groups
  enable_cluster_autoscaler     = var.enable_cluster_autoscaler
  enable_irsa                   = var.enable_irsa
  tags                          = var.common_tags
}

# Load Balancer Module
module "load_balancer" {
  source = "./modules/load-balancer"

  project_name              = var.project_name
  environment               = var.environment
  lb_type                   = var.load_balancer_type
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.public_subnet_ids
  security_group_ids        = [module.security_groups.load_balancer_security_group_id]
  internal                  = var.load_balancer_internal
  enable_deletion_protection = var.enable_deletion_protection
  tags                      = var.common_tags
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  cluster_name          = var.cluster_name
  cluster_endpoint      = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  storage_class_name    = var.storage_class_name
  storage_class_type    = var.storage_class_type
  volume_binding_mode   = var.volume_binding_mode
  reclaim_policy        = var.reclaim_policy
  allow_volume_expansion = var.allow_volume_expansion
  tags                  = var.common_tags
}

# Ingress Module
module "ingress" {
  source = "./modules/ingress"

  cluster_name              = var.cluster_name
  cluster_endpoint          = module.eks.cluster_endpoint
  cluster_ca_certificate    = module.eks.cluster_certificate_authority_data
  node_port                 = var.ingress_node_port
  nexus_registry_url        = var.nexus_registry_url
  nexus_registry_secret_name = var.nexus_registry_secret_name
  enable_ssl                = var.enable_ingress_ssl
  tags                      = var.common_tags
}

# Workloads Module
module "workloads" {
  source = "./modules/workloads"

  cluster_name              = var.cluster_name
  cluster_endpoint          = module.eks.cluster_endpoint
  cluster_ca_certificate    = module.eks.cluster_certificate_authority_data
  nexus_registry_url        = var.nexus_registry_url
  nexus_registry_secret_name = var.nexus_registry_secret_name
  enable_kafka              = var.enable_kafka
  enable_elk                = var.enable_elk
  enable_prometheus         = var.enable_prometheus
  enable_grafana            = var.enable_grafana
  kafka_node_selector       = var.kafka_node_selector
  elk_node_selector         = var.elk_node_selector
  monitoring_node_selector  = var.monitoring_node_selector
  tags                      = var.common_tags
}

