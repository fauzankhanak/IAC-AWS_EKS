# Quick Start Guide

This is a condensed guide to get you up and running quickly. For detailed documentation, see [README.md](README.md).

## Prerequisites Checklist

- [ ] AWS Account with appropriate permissions
- [ ] Terraform >= 1.0 installed
- [ ] AWS CLI configured
- [ ] kubectl installed
- [ ] Helm >= 3.0 installed
- [ ] S3 bucket for Terraform state (create if needed)
- [ ] DynamoDB table for state locking (create if needed)

## 5-Minute Setup

### 1. Configure Backend (2 minutes)

Edit `terraform.tf`:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "eks-cluster/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

Create S3 bucket and DynamoDB table (if needed):

```bash
aws s3 mb s3://your-terraform-state-bucket
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 2. Configure Variables (1 minute)

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
- `project_name`
- `environment`
- `cluster_name`
- `nexus_registry_url`
- `aws_region`

### 3. Deploy (15-20 minutes)

```bash
terraform init
terraform plan
terraform apply
```

### 4. Post-Deployment (5 minutes)

See [POST_DEPLOYMENT.md](POST_DEPLOYMENT.md) for:
- Installing EBS CSI driver
- Updating Nexus credentials
- Verifying workloads

## Common Commands

```bash
# Update kubeconfig
aws eks update-kubeconfig --name <cluster-name> --region <region>

# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# View Terraform outputs
terraform output

# Destroy infrastructure
terraform destroy
```

## Architecture Overview

```
Internet → ALB/NLB → NGINX Ingress (NodePort 30001) → EKS Cluster
                                                          ├── General Node Group
                                                          ├── Kafka Node Group
                                                          ├── Monitoring Node Group
                                                          └── Logging Node Group
```

## What Gets Created

- ✅ VPC with public/private subnets
- ✅ EKS cluster with encryption
- ✅ Multiple node groups
- ✅ ALB or NLB (your choice)
- ✅ NGINX ingress controller
- ✅ Storage classes
- ✅ Kafka, ELK, Prometheus, Grafana

## Next Steps

1. Complete post-deployment setup
2. Update Nexus registry credentials
3. Configure monitoring alerts
4. Review security groups
5. Set up CI/CD pipelines

For detailed information, see [README.md](README.md).

