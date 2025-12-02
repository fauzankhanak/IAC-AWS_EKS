# AWS EKS Infrastructure as Code

This repository contains a comprehensive, reusable, and idempotent Terraform infrastructure for provisioning a complete AWS EKS (Elastic Kubernetes Service) cluster with all necessary components following AWS and Kubernetes best practices.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Module Structure](#module-structure)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Backend Configuration](#backend-configuration)
- [Deployment](#deployment)
- [Components](#components)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Overview

This Terraform configuration provides a production-ready EKS cluster infrastructure that includes:

- **VPC Setup**: Custom VPC with public and private subnets, NAT gateways, and VPC endpoints
- **EKS Cluster**: Fully configured EKS cluster with encryption, logging, and IRSA support
- **Node Groups**: Configurable node groups with proper sizing for different workloads
- **Load Balancers**: Support for both Application Load Balancer (ALB) and Network Load Balancer (NLB)
- **Ingress Controller**: NGINX ingress controller deployed via NodePort
- **Storage**: Dynamic storage provisioning with StorageClass resources
- **Container Registry**: Integration with Nexus registry for secure image pulling
- **Monitoring & Logging**: Pre-configured Prometheus, Grafana, ELK stack, and Kafka
- **State Management**: S3 backend with DynamoDB locking

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└──────────────────────────┬──────────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │  Internet   │
                    │  Gateway    │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────▼────┐       ┌─────▼─────┐      ┌────▼────┐
   │ Public  │       │  Public   │      │ Public  │
   │Subnet 1 │       │ Subnet 2  │      │Subnet 3 │
   └────┬────┘       └─────┬─────┘      └────┬────┘
        │                  │                  │
        │            ┌──────▼──────┐          │
        │            │  NAT GW     │          │
        │            └──────┬──────┘          │
        │                  │                  │
   ┌────▼────┐       ┌─────▼─────┐      ┌────▼────┐
   │Private │       │  Private   │      │Private  │
   │Subnet 1│       │ Subnet 2   │      │Subnet 3 │
   └────┬────┘       └─────┬─────┘      └────┬────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                    ┌──────▼──────┐
                    │  EKS Cluster │
                    │  (Control    │
                    │   Plane)     │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────▼────┐       ┌─────▼─────┐      ┌────▼────┐
   │ Node    │       │   Node    │      │  Node   │
   │ Group 1 │       │  Group 2  │      │ Group 3 │
   │(General)│      │  (Kafka)   │      │(Monitor)│
   └─────────┘       └───────────┘      └─────────┘
```

## Features

### Core Infrastructure

- ✅ **Custom VPC** with public and private subnets across multiple availability zones
- ✅ **NAT Gateways** for private subnet internet access
- ✅ **VPC Endpoints** for S3 and EFS to optimize connectivity and reduce costs
- ✅ **Security Groups** following least-privilege principles
- ✅ **IAM Roles and Policies** following AWS security best practices

### EKS Cluster

- ✅ **EKS Cluster** with encryption at rest using KMS
- ✅ **CloudWatch Logging** for cluster control plane
- ✅ **IRSA (IAM Roles for Service Accounts)** support
- ✅ **Multiple Node Groups** with configurable instance types and sizing
- ✅ **Node Labels and Taints** for workload isolation

### Load Balancing

- ✅ **ALB Support** for HTTP/HTTPS traffic
- ✅ **NLB Support** for TCP/UDP traffic
- ✅ **Configurable** via variables

### Ingress

- ✅ **NGINX Ingress Controller** deployed via Helm
- ✅ **NodePort** configuration on port 30001
- ✅ **Nexus Registry Integration** for secure image pulling

### Storage

- ✅ **EBS StorageClass** for dynamic provisioning
- ✅ **EFS StorageClass** for shared storage
- ✅ **Configurable** volume binding modes and reclaim policies

### Workloads

- ✅ **Kafka** - Distributed streaming platform
- ✅ **ELK Stack** - Elasticsearch, Logstash, and Kibana for logging
- ✅ **Prometheus** - Metrics collection and alerting
- ✅ **Grafana** - Visualization and dashboards

### State Management

- ✅ **S3 Backend** for Terraform state storage
- ✅ **DynamoDB** for state locking
- ✅ **Encryption** enabled for state files

## Prerequisites

Before using this infrastructure, ensure you have:

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **kubectl** installed
5. **Helm** >= 3.0 installed
6. **S3 Bucket** for Terraform state (create manually or use existing)
7. **DynamoDB Table** for state locking (create manually or use existing)

### Required AWS Permissions

Your AWS credentials need permissions for:
- EC2 (VPC, subnets, security groups, instances)
- EKS (cluster and node group management)
- IAM (role and policy creation)
- S3 (backend state storage)
- DynamoDB (state locking)
- KMS (encryption keys)
- CloudWatch (logging)

## Module Structure

```
.
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Root module variables
├── outputs.tf                 # Root module outputs
├── terraform.tf               # Backend and provider configuration
├── terraform.tfvars.example   # Example variable values
├── .gitignore                 # Git ignore file
├── README.md                  # This file
└── modules/
    ├── vpc/                   # VPC module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── iam/                   # IAM roles and policies
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security-groups/       # Security groups
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── eks/                   # EKS cluster and node groups
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── load-balancer/         # ALB/NLB configuration
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ingress/               # NGINX ingress controller
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── storage/               # Kubernetes StorageClass
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── workloads/             # Kafka, ELK, Prometheus, Grafana
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd IAC
```

### 2. Configure Backend

Edit `terraform.tf` and configure the S3 backend:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "eks-cluster/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

### 3. Create S3 Bucket and DynamoDB Table

If you don't have them already, create them:

```bash
# Create S3 bucket for state
aws s3 mb s3://your-terraform-state-bucket --region us-east-1
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 4. Configure Variables

Copy the example variables file and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
project_name = "my-project"
environment  = "dev"
aws_region   = "us-east-1"
cluster_name = "my-project-dev-eks"
nexus_registry_url = "nexus.example.com:8082"
# ... other variables
```

### 5. Initialize Terraform

```bash
terraform init
```

### 6. Review the Plan

```bash
terraform plan
```

### 7. Apply the Configuration

```bash
terraform apply
```

This will take approximately 15-20 minutes to complete.

## Configuration

### VPC Configuration

The VPC module creates:
- Public subnets in each availability zone
- Private subnets in each availability zone
- Internet Gateway for public subnets
- NAT Gateways for private subnets (configurable)
- VPC endpoints for S3 and EFS

**Key Variables:**
- `vpc_cidr`: CIDR block for VPC (default: `10.0.0.0/16`)
- `availability_zones`: List of AZs to use
- `enable_nat_gateway`: Enable NAT gateways (default: `true`)
- `single_nat_gateway`: Use single NAT for cost savings (default: `false`)
- `enable_vpc_endpoints`: Enable S3/EFS endpoints (default: `true`)

### EKS Cluster Configuration

**Key Variables:**
- `cluster_name`: Name of the EKS cluster
- `cluster_version`: Kubernetes version (default: `1.28`)
- `enable_irsa`: Enable IAM Roles for Service Accounts (default: `true`)
- `enable_cluster_autoscaler`: Enable cluster autoscaler (default: `false`)

### Node Groups Configuration

Node groups are configured via the `node_groups` variable:

```hcl
node_groups = {
  general = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"  # or "SPOT"
    min_size      = 2
    max_size      = 5
    desired_size  = 3
    disk_size     = 50
    labels        = {
      workload-type = "general"
    }
    taints        = []
  }
}
```

**Best Practices:**
- Use separate node groups for different workload types (Kafka, monitoring, logging)
- Set appropriate labels and taints for workload isolation
- Size nodes based on workload requirements

### Load Balancer Configuration

Choose between ALB and NLB:

```hcl
load_balancer_type = "ALB"  # or "NLB"
load_balancer_internal = false
```

- **ALB**: Best for HTTP/HTTPS traffic, supports path-based routing
- **NLB**: Best for TCP/UDP traffic, lower latency

### Ingress Configuration

NGINX ingress controller is deployed on NodePort 30001:

```hcl
ingress_node_port = 30001
enable_ingress_ssl = false  # Set to true and configure certificates
```

### Storage Configuration

Storage classes are created for dynamic provisioning:

```hcl
storage_class_name    = "gp3"
storage_class_type    = "gp3"
volume_binding_mode   = "WaitForFirstConsumer"
reclaim_policy        = "Delete"
```

**Prerequisites:** The EBS CSI driver must be installed on the EKS cluster for storage provisioning to work. See the Storage Module README for installation instructions.

### Nexus Registry Integration

Configure Nexus registry for secure image pulling:

```hcl
nexus_registry_url        = "nexus.example.com:8082"
nexus_registry_secret_name = "nexus-registry-secret"
```

**Important:** The Nexus registry credentials are currently placeholder values. Before deploying to production:

1. **Store credentials in AWS Secrets Manager:**
   ```bash
   aws secretsmanager create-secret \
     --name nexus-registry-credentials \
     --secret-string '{"username":"your-username","password":"your-password"}' \
     --tags Key=Registry,Value=Nexus
   ```

2. **Update the ingress and workloads modules** to retrieve credentials from Secrets Manager using `data.aws_secretsmanager_secret_version`.

3. **Ensure the node group IAM role** has permissions to access Secrets Manager (already configured in the IAM module).

### Workloads Configuration

Enable/disable workloads:

```hcl
enable_kafka      = true
enable_elk        = true
enable_prometheus = true
enable_grafana    = true
```

Configure node selectors to route workloads to specific node groups:

```hcl
kafka_node_selector = {
  workload-type = "kafka"
}

monitoring_node_selector = {
  workload-type = "monitoring"
}
```

## Backend Configuration

### S3 Backend Setup

The Terraform state is stored in S3 with the following features:
- **Versioning**: Enabled for state file history
- **Encryption**: Server-side encryption enabled
- **State Locking**: DynamoDB table prevents concurrent modifications

### Configuring Backend

1. Create S3 bucket (if not exists):
```bash
aws s3 mb s3://your-terraform-state-bucket
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

2. Create DynamoDB table (if not exists):
```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

3. Update `terraform.tf` with your bucket and table names.

## Deployment

### Initial Deployment

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Plan the deployment:**
   ```bash
   terraform plan -out=tfplan
   ```

3. **Apply the configuration:**
   ```bash
   terraform apply tfplan
   ```

### Updating Configuration

1. Modify variables in `terraform.tfvars`
2. Review changes:
   ```bash
   terraform plan
   ```
3. Apply changes:
   ```bash
   terraform apply
   ```

### Destroying Infrastructure

⚠️ **Warning:** This will delete all resources!

```bash
terraform destroy
```

## Components

### VPC Module

Creates a production-ready VPC with:
- Public and private subnets across multiple AZs
- Internet Gateway for public subnets
- NAT Gateways for private subnets
- VPC endpoints for S3 and EFS
- Route tables and associations

### IAM Module

Creates IAM roles and policies:
- **EKS Cluster Role**: For the EKS control plane
- **Node Group Role**: For worker nodes with necessary permissions
- **Custom Policies**: For EFS access and Nexus registry integration

### Security Groups Module

Creates security groups:
- **Cluster Security Group**: For EKS control plane
- **Node Group Security Group**: For worker nodes
- **Load Balancer Security Group**: For ALB/NLB

### EKS Module

Creates:
- EKS cluster with encryption
- CloudWatch log groups
- KMS key for encryption
- Node groups with configurable sizing
- OIDC provider for IRSA

### Load Balancer Module

Creates either ALB or NLB:
- **ALB**: HTTP/HTTPS listeners with target groups
- **NLB**: TCP listener with target group
- Configurable security groups

### Ingress Module

Deploys NGINX ingress controller:
- Via Helm chart
- NodePort on port 30001
- Nexus registry integration
- Configurable resources

### Storage Module

Creates Kubernetes StorageClasses:
- **EBS StorageClass**: For persistent volumes
- **EFS StorageClass**: For shared storage (if EFS is configured)

### Workloads Module

Deploys additional workloads:
- **Kafka**: 3-node Kafka cluster with ZooKeeper
- **ELK Stack**: Elasticsearch, Logstash, Kibana
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization dashboards

## Security Best Practices

This infrastructure follows AWS and Kubernetes security best practices:

### Network Security

- ✅ Private subnets for worker nodes
- ✅ Security groups with least-privilege rules
- ✅ VPC endpoints to avoid internet traffic
- ✅ Encrypted communication between components

### IAM Security

- ✅ Separate IAM roles for cluster and nodes
- ✅ Least-privilege IAM policies
- ✅ IRSA for service account authentication
- ✅ No hardcoded credentials

### Cluster Security

- ✅ Encryption at rest using KMS
- ✅ Control plane logging enabled
- ✅ Private endpoint access (with public access for management)
- ✅ Security groups restricting access

### Container Security

- ✅ Nexus registry integration for image scanning
- ✅ Image pull secrets for private registries
- ✅ Resource limits on all workloads
- ✅ Network policies (can be added)

### State Security

- ✅ S3 backend with encryption
- ✅ DynamoDB locking to prevent conflicts
- ✅ Versioning enabled for state files

## Troubleshooting

### Common Issues

#### 1. Terraform State Lock Error

**Error:** `Error acquiring the state lock`

**Solution:**
```bash
# Check if lock exists
aws dynamodb scan --table-name terraform-state-lock

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

#### 2. EKS Cluster Not Accessible

**Error:** `Unable to connect to the server`

**Solution:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --name <cluster-name> --region <region>

# Verify access
kubectl get nodes
```

#### 3. Node Groups Not Joining

**Error:** Nodes not appearing in cluster

**Solution:**
- Check IAM role permissions
- Verify security group rules
- Check CloudWatch logs for node group
- Ensure subnets have proper tags

#### 4. Nexus Registry Authentication Failed

**Error:** `Failed to pull image`

**Solution:**
- Verify Nexus credentials in secrets
- Check image pull secrets are properly configured
- Ensure Nexus registry URL is correct

#### 5. StorageClass Not Working

**Error:** `PersistentVolumeClaim pending`

**Solution:**
- Verify EBS CSI driver is installed
- Check node group has proper IAM permissions
- Verify storage class parameters

### Useful Commands

```bash
# Get cluster info
aws eks describe-cluster --name <cluster-name>

# List node groups
aws eks list-nodegroups --cluster-name <cluster-name>

# Get node group details
aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name>

# View cluster logs
aws logs tail /aws/eks/<cluster-name>/cluster --follow

# Check Kubernetes resources
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get storageclass
```

## Contributing

### Module Development Guidelines

1. **Idempotency**: All resources must be idempotent
2. **Variables**: Use descriptive variable names with documentation
3. **Outputs**: Provide useful outputs for integration
4. **Tags**: Apply consistent tagging strategy
5. **Documentation**: Document all modules and resources

### Adding New Modules

1. Create module directory under `modules/`
2. Add `main.tf`, `variables.tf`, and `outputs.tf`
3. Update root `main.tf` to use the module
4. Add variables to root `variables.tf`
5. Add outputs to root `outputs.tf`
6. Update README.md

### Testing

Before applying to production:
1. Test in a dev environment
2. Review Terraform plan carefully
3. Verify all resources are created correctly
4. Test workload deployments
5. Verify security configurations

## Additional Resources

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

## License

This infrastructure code is provided as-is for use in your projects.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review AWS and Kubernetes documentation
3. Open an issue in the repository

---

**Note:** This infrastructure is designed to be production-ready but should be reviewed and customized based on your specific requirements and security policies.

