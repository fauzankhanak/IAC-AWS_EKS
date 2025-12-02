# Post-Deployment Setup Guide

This guide covers the steps required after the initial Terraform deployment to complete the EKS cluster setup.

## 1. Configure kubectl

After the cluster is created, configure kubectl to access your cluster:

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

Verify access:

```bash
kubectl get nodes
kubectl get namespaces
```

## 2. Install EBS CSI Driver

The EBS CSI driver is required for dynamic volume provisioning. Install it using one of the following methods:

### Option A: Using AWS EKS Add-on (Recommended)

```bash
# First, create an IAM role for the EBS CSI driver service account
# This requires IRSA to be enabled (already configured in the Terraform)

# Get the OIDC provider URL
OIDC_PROVIDER=$(aws eks describe-cluster --name <cluster-name> --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")

# Create IAM policy for EBS CSI driver
cat > ebs-csi-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSnapshot",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:CreateAction": [
            "CreateVolume",
            "CreateSnapshot"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:AvailabilityZone": "{{"{{"}} aws:RequestedRegion {{"}}"}}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:AvailabilityZone": "{{"{{"}} aws:RequestedRegion {{"}}"}}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/CSIVolumeName": "{{"{{"}} aws:RequestedTag/CSIVolumeName {{"}}"}}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/kubernetes.io/created-for/pvc/name": "{{"{{"}} aws:RequestedTag/kubernetes.io/created-for/pvc/name {{"}}"}}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/CSIVolumeSnapshotName": "{{"{{"}} aws:RequestedTag/CSIVolumeSnapshotName {{"}}"}}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/kubernetes.io/created-for/pvc/name": "{{"{{"}} aws:RequestedTag/kubernetes.io/created-for/pvc/name {{"}}"}}"
        }
      }
    }
  ]
}
EOF

# Create IAM role for EBS CSI driver
aws iam create-role \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --assume-role-policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Effect\": \"Allow\",
        \"Principal\": {
          \"Federated\": \"arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/${OIDC_PROVIDER}\"
        },
        \"Action\": \"sts:AssumeRoleWithWebIdentity\",
        \"Condition\": {
          \"StringEquals\": {
            \"${OIDC_PROVIDER}:sub\": \"system:serviceaccount:kube-system:ebs-csi-controller-sa\",
            \"${OIDC_PROVIDER}:aud\": \"sts.amazonaws.com\"
          }
        }
      }
    ]
  }"

# Attach policy to role
aws iam put-role-policy \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --policy-name AmazonEBSCSIDriverPolicy \
  --policy-document file://ebs-csi-policy.json

# Create service account
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ebs-csi-controller-sa
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/AmazonEKS_EBS_CSI_DriverRole
EOF

# Install the addon
aws eks create-addon \
  --cluster-name <cluster-name> \
  --addon-name aws-ebs-csi-driver \
  --service-account-role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/AmazonEKS_EBS_CSI_DriverRole \
  --region <region>
```

### Option B: Using Helm

```bash
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system \
  --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::<account-id>:role/AmazonEKS_EBS_CSI_DriverRole
```

## 3. Install EFS CSI Driver (Optional)

If you plan to use EFS storage, install the EFS CSI driver:

```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.7"
```

**Note:** You'll need to create an EFS file system and update the StorageClass with the file system ID.

## 4. Verify Storage Classes

Check that StorageClasses are created:

```bash
kubectl get storageclass
```

You should see `gp3` as the default storage class.

## 5. Update Nexus Registry Credentials

The Nexus registry secrets currently contain placeholder credentials. Update them:

### Option A: Using AWS Secrets Manager (Recommended)

1. Store credentials in Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name nexus-registry-credentials \
  --secret-string '{"username":"your-username","password":"your-password"}' \
  --tags Key=Registry,Value=Nexus
```

2. Update the Terraform modules to retrieve from Secrets Manager (see module code for TODO comments).

### Option B: Manual Update

Update the Kubernetes secrets directly:

```bash
# Get base64 encoded credentials
echo -n 'your-username:your-password' | base64

# Update the secret
kubectl create secret docker-registry nexus-registry-secret \
  --docker-server=<nexus-registry-url> \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  --namespace=<namespace> \
  --dry-run=client -o yaml | kubectl apply -f -
```

## 6. Verify Workloads

Check that all workloads are running:

```bash
# Check monitoring stack
kubectl get pods -n monitoring

# Check logging stack
kubectl get pods -n logging

# Check Kafka
kubectl get pods -n kafka

# Check ingress
kubectl get pods -n ingress-nginx
```

## 7. Access Grafana

Get the Grafana admin password:

```bash
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Port-forward to access Grafana:

```bash
kubectl port-forward --namespace monitoring svc/grafana 3000:80
```

Access at: http://localhost:3000
- Username: `admin`
- Password: (from above command)

## 8. Access Prometheus

Port-forward to access Prometheus:

```bash
kubectl port-forward --namespace monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Access at: http://localhost:9090

## 9. Access Kibana

Port-forward to access Kibana:

```bash
kubectl port-forward --namespace logging svc/kibana-kibana 5601:5601
```

Access at: http://localhost:5601

## 10. Configure Load Balancer Target Groups

After the ingress controller is running, register the node group instances with the load balancer target groups:

```bash
# Get node group instance IDs
aws eks describe-nodegroup \
  --cluster-name <cluster-name> \
  --nodegroup-name <nodegroup-name> \
  --query 'nodegroup.resources.remoteAccessSecurityGroup' \
  --output text

# Register instances with target group (ALB)
# This is typically handled automatically by Kubernetes, but verify:
kubectl get svc -n ingress-nginx
```

## 11. Test Storage Provisioning

Create a test PVC to verify storage works:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 1Gi
EOF

# Check PVC status
kubectl get pvc test-pvc

# Clean up
kubectl delete pvc test-pvc
```

## Troubleshooting

### EBS CSI Driver Not Working

1. Check if the addon is installed:
   ```bash
   aws eks describe-addon --cluster-name <cluster-name> --addon-name aws-ebs-csi-driver
   ```

2. Check pod status:
   ```bash
   kubectl get pods -n kube-system | grep ebs-csi
   ```

3. Check logs:
   ```bash
   kubectl logs -n kube-system -l app=ebs-csi-controller
   ```

### Nexus Registry Authentication Failed

1. Verify secret exists:
   ```bash
   kubectl get secret nexus-registry-secret -n <namespace>
   ```

2. Check secret content:
   ```bash
   kubectl get secret nexus-registry-secret -n <namespace> -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d
   ```

3. Test image pull manually:
   ```bash
   kubectl run test-pod --image=<nexus-registry-url>/test-image:latest --restart=Never
   kubectl describe pod test-pod
   ```

### Workloads Not Starting

1. Check pod events:
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   ```

2. Check node resources:
   ```bash
   kubectl top nodes
   kubectl describe nodes
   ```

3. Check node selectors match:
   ```bash
   kubectl get nodes --show-labels
   ```

## Next Steps

- Configure network policies for additional security
- Set up backup strategies for persistent volumes
- Configure autoscaling for node groups
- Set up monitoring alerts
- Configure log aggregation
- Review and harden security groups
- Set up CI/CD pipelines

