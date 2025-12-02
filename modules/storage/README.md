# Storage Module

This module creates Kubernetes StorageClass resources for dynamic volume provisioning.

## Prerequisites

Before using this module, ensure the EBS CSI driver is installed on your EKS cluster:

```bash
# Add the EBS CSI driver addon
aws eks create-addon \
  --cluster-name <cluster-name> \
  --addon-name aws-ebs-csi-driver \
  --service-account-role-arn <irsa-role-arn> \
  --region <region>
```

Or install via Helm:

```bash
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system
```

## EFS CSI Driver

For EFS storage, install the EFS CSI driver:

```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.7"
```

Note: Update the EFS file system ID in the StorageClass after creating an EFS file system.

