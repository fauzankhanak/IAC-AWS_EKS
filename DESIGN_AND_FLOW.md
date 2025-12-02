## Design and Flow of the Terraform EKS Platform

This document explains **what** each part of the Terraform code does, **why** it was designed that way, and **how** the whole flow works from `terraform apply` to a running EKS platform.

- **Audience**: DevOps / Platform engineers who will read, extend, and operate this code.
- **Goal**: Make it easy to understand and safely modify the infrastructure.

---

## 1. High‑level Architecture and Design Goals

### 1.1 What we are building

Conceptually, the platform is split into these layers:

1. **Network layer** – `VPC`, subnets, routing, NAT, and VPC endpoints
2. **Security & IAM layer** – IAM roles, policies, security groups, AWS security services
3. **EKS control plane & node layer** – EKS cluster, node groups, encryption, logging
4. **Access & edge layer** – Load balancer, NGINX ingress
5. **Data & storage layer** – StorageClasses for EBS/EFS
6. **Platform workloads** – Kafka, ELK, Prometheus, Grafana
7. **Security services & monitoring** – GuardDuty, Security Hub, Config, CloudTrail, WAF, Inspector
8. **Secrets & registry integration** – AWS Secrets Manager + Nexus
9. **Kubernetes security** – Pod Security Standards, NetworkPolicies, quotas

The code is organized into **small, focused modules** so that:

- Each concern (VPC, IAM, EKS, ingress, etc.) is isolated
- Modules can be reused or swapped out (e.g. different ingress or logging stack)
- Multiple engineers can work in parallel without stepping on each other

---

## 2. Backend, Providers, and State

### 2.1 `terraform.tf` – Backend & required providers

We use an **S3 backend with DynamoDB locking**:

- **Why S3**: Central, durable storage for Terraform state so all engineers share the same view of infrastructure.
- **Why DynamoDB locking**: Prevents two people running `terraform apply` at the same time from corrupting the state.
- **Encryption**: Enabled on the bucket to protect state (which may contain sensitive IDs, ARNs, etc.).

Required providers:

- `aws` – All AWS infrastructure
- `kubernetes` – Kubernetes objects (StorageClass, NetworkPolicy, etc.) on the EKS cluster
- `helm` – Deploy Helm charts (NGINX, Prometheus, Grafana, Kafka, ELK)

Design choice: **All AWS infrastructure is created first**, then the Kubernetes/Helm pieces configure the cluster on top of that.

### 2.2 `provider "aws"` in `main.tf`

We configure a single AWS provider with:

- `region = var.aws_region` – Region is configurable
- `default_tags` – Enforces consistent tagging (Project, Environment, ManagedBy)

**Why**: Tags are critical for cost allocation, operations, and compliance. Centralizing them avoids drift.

---

## 3. Root Module (`main.tf`, `variables.tf`, `outputs.tf`)

### 3.1 Responsibility of the root module

The root module:

- Wires all child modules together
- Owns **environment‑wide variables** (project name, environment, regions, enable flags)
- Defines sensible defaults (e.g. node groups, storage types)

It does **not** create low‑level resources directly (no `aws_vpc` in root). That keeps the entry point readable.

### 3.2 Execution flow during `terraform apply`

At a high level, Terraform will:

1. Create the **VPC** (`module.vpc`)
2. Create **IAM roles/policies** (`module.iam`)
3. Create **security groups** (`module.security_groups`)
4. Create **EKS cluster + node groups** (`module.eks`)
5. Create **AWS security services** (`module.security`)
6. Create **Secrets Manager secret** for Nexus (`module.secrets_manager`)
7. Create **load balancer** (`module.load_balancer`) and **associate WAF** if enabled
8. Configure **Kubernetes StorageClasses** (`module.storage`)
9. Apply **Kubernetes security controls** (`module.kubernetes_security`)
10. Deploy **NGINX ingress** (`module.ingress`)
11. Deploy **workloads** – Kafka, ELK, Prometheus, Grafana (`module.workloads`)

Terraform builds a dependency graph automatically from resource references, so, for example:

- `module.eks` depends on VPC + IAM + security groups
- `module.ingress` and `module.workloads` depend on the EKS cluster endpoint and CA
- `module.load_balancer` depends on VPC and security groups

**Takeaway**: You rarely need explicit `depends_on` in root; wiring via outputs/inputs is enough.

---

## 4. Network Layer – `modules/vpc`

### 4.1 What it creates

- `aws_vpc` – Custom VPC CIDR (default `10.0.0.0/16`)
- **Public subnets** in each AZ – With `map_public_ip_on_launch = true`
- **Private subnets** in each AZ – For worker nodes and internal services
- `aws_internet_gateway`
- `aws_nat_gateway` + `aws_eip` – For outbound internet from private subnets
- Route tables for public and private subnets
- VPC endpoints:
  - S3 (gateway endpoint) – for S3 access without internet
  - EFS (interface endpoint) – for EFS CSI driver and workloads

### 4.2 Why this design

- **Public subnets**: For load balancers, bastion (if used), and internet ingress.
- **Private subnets**: Worker nodes and internal services stay off the public internet.
- **NAT gateways**: Private instances can access the internet for updates, pulling images, etc., but are not directly reachable.
- **VPC endpoints**: Optimize traffic and avoid routing S3/EFS traffic over public internet.

Best practice: Each AZ gets 1 public + 1 private subnet to maintain high availability across zones.

---

## 5. IAM & Security Groups – `modules/iam`, `modules/security-groups`

### 5.1 IAM (`modules/iam`)

Creates:

- **Cluster role** (`aws_iam_role.cluster`) – Assumed by `eks.amazonaws.com`
- **Node group role** (`aws_iam_role.node_group`) – Assumed by `ec2.amazonaws.com`
- Managed policy attachments:
  - `AmazonEKSClusterPolicy`
  - `AmazonEKSVPCResourceController`
  - `AmazonEKSWorkerNodePolicy`
  - `AmazonEKS_CNI_Policy`
  - `AmazonEC2ContainerRegistryReadOnly`
- Custom policies:
  - For EFS access
  - For Secrets Manager access to Nexus credentials (tag‑based)

**Why**:

- EKS and worker nodes need AWS API permissions; using **separate roles** enforces least privilege.
- Custom policies are scoped to secrets with specific tags (e.g. `Registry=Nexus`), avoiding overly broad access.

### 5.2 Security groups (`modules/security-groups`)

Creates:

- **Cluster SG** – For control plane
- **Node SG** – For worker nodes
- **Load balancer SG** – For ALB/NLB

Key rules:

- Nodes can talk to the cluster on 443
- Nodes can talk to each other (for services, overlay networking)
- NodePort range 30000–32767 open within VPC CIDR
- Load balancer ports 80/443 open from the internet

**Why**:

- Mirror AWS EKS best practice patterns but keep rules minimal and explicit.

---

## 6. EKS Cluster & Node Groups – `modules/eks`

### 6.1 What it creates

- `aws_eks_cluster` – Control plane
- `aws_kms_key` – For secret encryption
- `aws_cloudwatch_log_group` – For cluster logs
- `aws_eks_node_group` (for each entry in `var.node_groups`)
- Optional `aws_iam_openid_connect_provider` – for IRSA

### 6.2 Why we use node groups and labels/taints

`var.node_groups` allows defining **logical node pools**:

- **General** – For generic workloads
- **Kafka** – Larger instance types, more disk
- **Monitoring** – For Prometheus/Grafana
- **Logging** – For ELK

Each node group can define:

- Instance types
- Min/max/desired size
- Disk size
- Labels and taints

**Why**:

- Workloads with very different profiles (Kafka vs Prometheus vs microservices) should not share identical nodes.
- Labels/taints allow scheduling and isolation (e.g. Kafka only on `workload-type=kafka` nodes).

### 6.3 Encryption and logging

- Secrets in etcd are encrypted with a dedicated **KMS key**.
- Control plane logs (API, audit, authenticator, controller, scheduler) go to CloudWatch.

**Why**:

- Encryption at rest is a security requirement for many orgs.
- Audit logging is essential for incident response and compliance.

---

## 7. Load Balancer & WAF – `modules/load-balancer`

### 7.1 ALB vs NLB

You can choose via `var.load_balancer_type`:

- **ALB (HTTP/HTTPS)**:
  - Good for L7 routing, path‑based routing, WAF integration
- **NLB (TCP)**:
  - Good for low‑latency, L4 traffic (e.g. TCP services)

The module creates:

- ALB or NLB (`aws_lb`)
- Target groups (HTTP/HTTPS for ALB, TCP for NLB)
- Listeners
- **Optional WAF association** via `aws_wafv2_web_acl_association`

### 7.2 Why WAF

- Adds a **L7 protection layer** against common web vulnerabilities and volumetric attacks:
  - Managed rule sets (OWASP, SQLi, bad inputs)
  - Rate limiting per IP
- Integrated metrics for monitoring in CloudWatch.

---

## 8. Storage Layer – `modules/storage`

### 8.1 What it does

Creates Kubernetes `StorageClass` objects:

- **EBS** StorageClass (default, gp3)
- Optional EFS StorageClass

**Why**:

- Dynamic provisioning allows workloads to request volumes via PVCs without manual PV management.
- `WaitForFirstConsumer` binding mode is used to avoid scheduling volumes in the wrong AZ.

Prerequisite: EBS (and EFS) CSI drivers must be installed (documented in `POST_DEPLOYMENT.md` and `modules/storage/README.md`).

---

## 9. Ingress & Nexus Integration – `modules/ingress`

### 9.1 NGINX ingress on NodePort

We install **ingress-nginx** via Helm:

- Service type: `NodePort` on port `30001` (HTTP) / `30002` (HTTPS)
- Fronted by ALB/NLB that points to this NodePort

**Why NodePort**:

- Keeps control over the external load balancer layer in Terraform (ALB/NLB), decoupled from the cluster.
- Makes it easy to switch LB type or front multiple clusters behind a single ingress or DNS layer.

### 9.2 Nexus registry integration

The module:

- Creates a `kubernetes_secret` of type `dockerconfigjson` for Nexus
- Image repository for ingress controller points to Nexus (e.g. `<nexus-url>/ingress-nginx/controller`)
- Pulls credentials logically from Secrets Manager (pattern in comments)

**Why**:

- Centralized, private registry (Nexus) for all images (including base infra components) improves:
  - Control over versions
  - Ability to scan images
  - Isolation from public registry outages

---

## 10. Workloads – `modules/workloads`

### 10.1 What it deploys

- **Prometheus** (kube‑prometheus‑stack)
- **Grafana**
- **Kafka** (Bitnami Kafka with ZooKeeper)
- **ELK** (Elasticsearch, Logstash, Kibana)

Each workload:

- Uses proper resource requests/limits
- Uses persistent volumes via `StorageClass` (gp3)
- Uses node selectors to target the right node groups
- Can use Nexus registry image sources

### 10.2 Why deploy these with the cluster

These are “platform services” that almost every app team will need:

- Observability: Prometheus + Grafana
- Centralized logging: ELK
- Messaging/streaming: Kafka

Deploying them as part of the infrastructure:

- Ensures consistent, reproducible environments across dev/stage/prod.
- Gives platform team full control over sizing, security, and lifecycle.

---

## 11. AWS Security Services – `modules/security`

### 11.1 GuardDuty

- Detector with S3, Kubernetes, and malware protection enabled.
- Monitors for suspicious patterns (e.g. port scans, IAM anomalies, compromised credentials).

**Why**: Always‑on threat detection with very low operational overhead.

### 11.2 Security Hub

- Enables default standards:
  - CIS AWS Foundations
  - AWS Foundational Security Best Practices
- Aggregates findings from GuardDuty, Inspector, Config, IAM Access Analyzer, etc.

**Why**: Gives a single pane of glass for security posture and compliance.

### 11.3 Config

- Configuration recorder, delivery channel, rules for:
  - EKS logging
  - EKS endpoint access
  - Encrypted volumes
  - VPC flow logs enabled

**Why**: Ensures resources remain compliant and misconfigurations are detected.

### 11.4 CloudTrail

- Multi‑region trail
- Logs to encrypted, versioned S3 bucket and CloudWatch Logs.

**Why**: Immutable audit trail of API calls, mandatory for investigations and audits.

### 11.5 WAF

- Web ACL with managed rule groups and rate limit rule
- Associated with ALB when enabled

**Why**: Protects HTTP/HTTPS apps from OWASP Top 10 and simple DDoS.

### 11.6 Inspector v2

- Enables scanning for EC2, ECR, Lambda.

**Why**: Continuous vulnerability management for runtime and container images.

---

## 12. Secrets Management – `modules/secrets-manager`

### 12.1 Nexus credentials

We store Nexus credentials in **AWS Secrets Manager**:

- `aws_secretsmanager_secret` – Metadata, KMS key, tags (`Registry=Nexus`)
- `aws_secretsmanager_secret_version` – Contains JSON `{ username, password, url }`

**Why**:

- Central, encrypted, auditable storage of secrets
- Easy integration with IRSA and Kubernetes
- No secrets hardcoded in Terraform code or state (you should pass them via environment or external secrets).

### 12.2 Access policy

`aws_iam_policy.nexus_secret_access` grants:

- `secretsmanager:GetSecretValue`, `DescribeSecret` on that secret
- `kms:Decrypt` via condition tied to Secrets Manager

Node group role in IAM module is given permission via this policy (or its equivalent), enabling pods (via IRSA) to fetch credentials securely.

---

## 13. Kubernetes Security – `modules/kubernetes-security`

### 13.1 Pod Security Standards (PSS)

We label key namespaces with PSS labels:

- `pod-security.kubernetes.io/enforce`, `audit`, `warn`
- Different levels per namespace (`privileged` for system, `baseline/restricted` for workloads)

**Why**:

- Enforce minimum security posture for pods (e.g. no privileged containers in standard namespaces).

### 13.2 NetworkPolicies

Examples:

- `default-deny-all` in `default` namespace
- Restrictive policies in `monitoring` and `logging`

**Why**:

- Ensure pods cannot freely talk to everything; reduce blast radius.

### 13.3 Resource quotas and limit ranges

- LimitRanges in default namespace for CPU/memory defaults and max
- ResourceQuota for total CPU/memory and pod count

**Why**:

- Prevent any single app or team from exhausting cluster resources.

---

## 14. How Everything Flows Together

### 14.1 Infrastructure flow

1. **Terraform backend** connects to S3 and DynamoDB for state/locks.
2. **VPC** is created with subnets, IGW, NAT, endpoints.
3. **IAM roles & security groups** are created.
4. **EKS cluster** is created and joined by node groups.
5. **Security services** (GuardDuty, Security Hub, Config, CloudTrail, Inspector, WAF) are enabled and wired to S3/CloudWatch.
6. **Secrets Manager** stores Nexus credentials.
7. **Load balancer** is created and (optionally) protected with WAF.
8. **Kubernetes StorageClasses** are created for EBS/EFS.
9. **Kubernetes security** (PSS, NetworkPolicies, quotas) is applied.
10. **Ingress** controller is deployed and configured to use Nexus images and secrets.
11. **Workloads** (Kafka, ELK, Prometheus, Grafana) are deployed into their namespaces.

### 14.2 Runtime traffic flow

1. External user → **ALB/NLB** DNS name
2. Load balancer → **NodePort 30001** on worker nodes (NGINX ingress controller)
3. NGINX routes to **Kubernetes services** in the cluster
4. Services use **StorageClasses** to request volumes where needed
5. Logging and metrics sent to **ELK** and **Prometheus/Grafana**
6. AWS security services continuously **monitor, log, and detect** threats

---

## 15. How to Extend the Platform Safely

### 15.1 Adding a new module

1. Create `modules/<name>/{main.tf,variables.tf,outputs.tf}`
2. Keep the module focused on one concern
3. Wire inputs/outputs via `main.tf` in root
4. Document the module in `README.md` and, if complex, in a dedicated section here

### 15.2 Adding a new workload

1. Decide if it is a **platform** workload → put into `modules/workloads`, or a **team app** → separate repo.
2. Use Helm via `helm_release` when possible.
3. Use node selectors to target appropriate node groups.
4. Define resource requests/limits and, if needed, PDBs and NetworkPolicies.

### 15.3 Changing security posture

Examples:

- Tighten PSS to `restricted` for certain namespaces
- Add more WAF rules (geo blocking, custom patterns)
- Add more Config rules or Security Hub controls

Best practice: Make changes via variables in root where possible and keep default configs secure by default.

---

## 16. Where to Read Next

- `README.md` – High‑level usage, commands, and quick overview
- `SECURITY.md` – Deep dive into security controls
- `POST_DEPLOYMENT.md` – What to do after `terraform apply`
- `QUICK_START.md` – Minimal steps to get a cluster running

Use this `DESIGN_AND_FLOW.md` when:

- Onboarding new engineers to the platform
- Planning architectural changes
- Reviewing pull requests that touch multiple modules


