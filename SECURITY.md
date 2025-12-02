# Security Documentation

This document describes the comprehensive security features implemented in this EKS infrastructure using AWS security services.

## Overview

The infrastructure implements defense-in-depth security using multiple AWS security services and Kubernetes security features to protect your EKS cluster and workloads.

## AWS Security Services

### 1. AWS GuardDuty

**Purpose**: Continuous threat detection and monitoring

**Features Enabled**:
- ✅ S3 Protection - Monitors S3 buckets for suspicious activity
- ✅ Kubernetes Protection - Monitors EKS audit logs for threats
- ✅ Malware Protection - Scans EBS volumes for malware
- ✅ Finding publishing frequency: 15 minutes

**Configuration**:
```hcl
enable_guardduty = true
```

**Access**:
- View findings in AWS Console: GuardDuty → Findings
- Set up CloudWatch Events/EventBridge rules to alert on critical findings

### 2. AWS Security Hub

**Purpose**: Centralized security findings aggregation and compliance monitoring

**Standards Enabled**:
- ✅ CIS AWS Foundations Benchmark v1.2.0
- ✅ AWS Foundational Security Best Practices v1.0.0

**Configuration**:
```hcl
enable_security_hub = true
```

**Access**:
- View findings: AWS Console → Security Hub → Findings
- Security scores and compliance status are automatically calculated

### 3. AWS Config

**Purpose**: Compliance monitoring and resource configuration tracking

**Rules Configured**:
- ✅ `EKS_CLUSTER_LOGGING_ENABLED` - Ensures EKS cluster logging is enabled
- ✅ `EKS_ENDPOINT_PUBLIC_ACCESS_CHECK` - Validates endpoint access configuration
- ✅ `EKS_ENDPOINT_PRIVATE_ACCESS_CHECK` - Ensures private endpoint access
- ✅ `ENCRYPTED_VOLUMES` - Verifies EBS volumes are encrypted
- ✅ `VPC_FLOW_LOGS_ENABLED` - Checks for VPC flow logs

**Configuration**:
```hcl
enable_config = true
config_s3_bucket = ""  # Auto-created if empty
```

**Access**:
- View compliance: AWS Console → Config → Rules
- Configuration history: Config → Resources → Configuration timeline

### 4. AWS CloudTrail

**Purpose**: API activity logging and audit trail

**Features**:
- ✅ Multi-region trail
- ✅ Log file validation enabled
- ✅ CloudWatch Logs integration
- ✅ S3 bucket with versioning and encryption
- ✅ Event selectors for S3 and Lambda

**Configuration**:
```hcl
enable_cloudtrail = true
cloudtrail_s3_bucket = ""  # Auto-created if empty
```

**Access**:
- View logs: AWS Console → CloudTrail → Event history
- CloudWatch Logs: `/aws/cloudtrail/<project>-<environment>`

### 5. AWS WAF (Web Application Firewall)

**Purpose**: Protect load balancers from common web exploits

**Rules Configured**:
- ✅ AWS Managed Rules - Common Rule Set (OWASP Top 10)
- ✅ AWS Managed Rules - Known Bad Inputs
- ✅ AWS Managed Rules - Linux Rule Set
- ✅ AWS Managed Rules - SQL Injection Protection
- ✅ Rate Limiting Rule (2000 requests per 5 minutes per IP)

**Configuration**:
```hcl
enable_waf = true
waf_scope = "REGIONAL"  # For ALB/NLB
```

**Association**:
- Automatically associated with ALB when enabled
- For NLB, manual association may be required

**Access**:
- View metrics: AWS Console → WAF → Web ACLs → Metrics
- View blocked requests: CloudWatch Metrics

### 6. AWS Inspector

**Purpose**: Automated vulnerability assessment

**Resource Types Scanned**:
- ✅ EC2 instances
- ✅ ECR container images
- ✅ Lambda functions

**Configuration**:
```hcl
enable_inspector = true
```

**Note**: Inspector v2 uses continuous scanning. Findings are automatically generated.

**Access**:
- View findings: AWS Console → Inspector → Findings

## Secrets Management

### AWS Secrets Manager

**Purpose**: Secure storage and rotation of sensitive credentials

**Secrets Stored**:
- Nexus registry credentials (username, password, URL)

**Features**:
- ✅ KMS encryption at rest
- ✅ IAM policy for access control
- ✅ Integration with Kubernetes via IRSA

**Configuration**:
```hcl
nexus_username = "your-username"  # Use TF_VAR_nexus_username
nexus_password = "your-password"  # Use TF_VAR_nexus_password
```

**Best Practices**:
1. Use environment variables for sensitive values:
   ```bash
   export TF_VAR_nexus_username="your-username"
   export TF_VAR_nexus_password="your-password"
   ```

2. Enable automatic rotation (configure separately):
   ```bash
   aws secretsmanager rotate-secret \
     --secret-id <secret-arn> \
     --rotation-lambda-arn <lambda-arn>
   ```

## Kubernetes Security

### Pod Security Standards

**Purpose**: Enforce security policies at the pod level

**Levels Configured**:
- `privileged`: kube-system, kube-public, kube-node-lease
- `baseline`: default, ingress-nginx, monitoring, logging, kafka (configurable)

**Configuration**:
```hcl
enable_pod_security_standards = true
pod_security_standard_level   = "baseline"  # or "restricted"
```

**What It Enforces**:
- Prevents running as root (baseline/restricted)
- Requires security contexts
- Restricts host namespace access
- Limits volume types

### Network Policies

**Purpose**: Micro-segmentation and network isolation

**Policies Configured**:
- Default namespace: Deny all ingress/egress by default
- Monitoring namespace: Restricted access to Prometheus
- Logging namespace: Controlled access to Elasticsearch

**Configuration**:
```hcl
enable_network_policies = true
```

### Resource Quotas and Limits

**Purpose**: Prevent resource exhaustion and enforce fair usage

**Configured**:
- Default namespace: CPU/memory limits and requests
- Limit ranges for all namespaces
- Pod disruption budgets for critical workloads

## EKS Cluster Security

### Encryption

- ✅ **At Rest**: KMS encryption for EKS secrets
- ✅ **In Transit**: TLS for all API communications
- ✅ **EBS Volumes**: Encryption enabled via StorageClass

### Access Control

- ✅ **IRSA**: IAM Roles for Service Accounts
- ✅ **Private Endpoint**: Control plane endpoint access control
- ✅ **Public Endpoint**: Restricted CIDR blocks (configurable)

### Logging

- ✅ **Control Plane Logs**: CloudWatch Logs for API, audit, authenticator, controller, scheduler
- ✅ **Retention**: 7 days (configurable)

## Security Best Practices Implemented

### Network Security

1. ✅ Private subnets for worker nodes
2. ✅ Security groups with least-privilege rules
3. ✅ VPC endpoints to avoid internet exposure
4. ✅ Network policies for pod-to-pod communication

### IAM Security

1. ✅ Separate roles for cluster and nodes
2. ✅ Least-privilege policies
3. ✅ IRSA for service accounts
4. ✅ No hardcoded credentials

### Container Security

1. ✅ Nexus registry integration
2. ✅ Image pull secrets
3. ✅ Resource limits on all workloads
4. ✅ Pod Security Standards enforcement

### Data Security

1. ✅ Encryption at rest (KMS)
2. ✅ Encryption in transit (TLS)
3. ✅ Secrets in AWS Secrets Manager
4. ✅ S3 bucket encryption

### Monitoring and Compliance

1. ✅ GuardDuty for threat detection
2. ✅ Security Hub for compliance
3. ✅ Config for configuration compliance
4. ✅ CloudTrail for audit logging

## Security Monitoring

### Setting Up Alerts

1. **GuardDuty Alerts**:
   ```bash
   # Create EventBridge rule for critical findings
   aws events put-rule \
     --name guardduty-critical-findings \
     --event-pattern '{"source":["aws.guardduty"],"detail-type":["GuardDuty Finding"]}'
   ```

2. **Security Hub Alerts**:
   - Configure in Security Hub → Settings → Notifications
   - Set up SNS topics for critical findings

3. **Config Compliance Alerts**:
   - Use Config → Rules → Compliance notifications
   - Set up SNS for non-compliant resources

### Viewing Security Findings

1. **GuardDuty**: AWS Console → GuardDuty → Findings
2. **Security Hub**: AWS Console → Security Hub → Findings
3. **Inspector**: AWS Console → Inspector → Findings
4. **Config**: AWS Console → Config → Compliance

## Compliance and Auditing

### Compliance Frameworks

The infrastructure supports:
- ✅ CIS AWS Foundations Benchmark
- ✅ AWS Foundational Security Best Practices
- ✅ SOC 2 (with additional controls)
- ✅ PCI DSS (with additional controls)

### Audit Trail

All activities are logged:
- ✅ API calls: CloudTrail
- ✅ Configuration changes: Config
- ✅ Security events: GuardDuty
- ✅ Compliance status: Security Hub

## Incident Response

### Automated Response

1. **GuardDuty Findings**: Can trigger Lambda functions for automated response
2. **WAF Blocks**: Automatically block malicious traffic
3. **Config Non-Compliance**: Can trigger remediation actions

### Manual Response

1. Review findings in Security Hub
2. Investigate GuardDuty threats
3. Check CloudTrail for suspicious API calls
4. Review Config compliance status

## Security Hardening Checklist

- [x] Enable GuardDuty
- [x] Enable Security Hub
- [x] Enable Config
- [x] Enable CloudTrail
- [x] Enable WAF
- [x] Enable Inspector
- [x] Store secrets in Secrets Manager
- [x] Enable Pod Security Standards
- [x] Configure Network Policies
- [x] Enable encryption at rest
- [x] Enable encryption in transit
- [x] Configure resource quotas
- [x] Set up monitoring and alerting
- [ ] Configure automatic secret rotation
- [ ] Set up automated remediation
- [ ] Configure VPC Flow Logs
- [ ] Enable AWS Shield (DDoS protection)
- [ ] Configure AWS Macie (data discovery)

## Additional Security Recommendations

1. **Enable VPC Flow Logs**: For network traffic analysis
   ```hcl
   # Add to VPC module
   resource "aws_flow_log" "vpc" {
     ...
   }
   ```

2. **Enable AWS Shield**: For DDoS protection (Advanced tier recommended)

3. **Configure AWS Macie**: For sensitive data discovery in S3

4. **Set up Automated Remediation**: Use Systems Manager Automation or Lambda

5. **Regular Security Reviews**: 
   - Weekly: Review Security Hub findings
   - Monthly: Review GuardDuty trends
   - Quarterly: Full security audit

6. **Access Reviews**: Regularly review IAM roles and policies

7. **Image Scanning**: Integrate ECR image scanning or third-party tools

8. **Runtime Security**: Consider Falco or similar runtime security tools

## Cost Considerations

Security services costs (approximate monthly):
- GuardDuty: ~$0.10 per GB of data analyzed
- Security Hub: Free for first 100,000 findings/month
- Config: ~$0.003 per configuration item recorded
- CloudTrail: Free for first trail, S3 storage costs apply
- WAF: ~$5/month per web ACL + $1 per million requests
- Inspector: Free tier available, then pay-per-use

## Support and Resources

- [AWS GuardDuty Documentation](https://docs.aws.amazon.com/guardduty/)
- [AWS Security Hub Documentation](https://docs.aws.amazon.com/securityhub/)
- [AWS Config Documentation](https://docs.aws.amazon.com/config/)
- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

