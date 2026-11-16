# Self-Hosted GitHub Actions Runners on EKS

> Ephemeral, IRSA-authenticated, hardened runners on Amazon EKS using Actions Runner Controller (ARC)

---

## Overview

This guide documents the end-to-end setup of self-hosted ephemeral GitHub Actions runners on Amazon EKS using Actions Runner Controller (ARC), with IRSA-based identity, hardened pod security, and Wiz-scanned runner images.

**Security objectives:**
- No code or credentials leaving the private network
- Full audit trail of every pipeline execution via CloudTrail
- Least-privilege pod-level identity using IRSA — no long-lived credentials
- Ephemeral runners — pod destroyed after every job

---

## Prerequisites

- EKS cluster (1.27+) running and `kubectl` configured
- Helm 3.x installed
- AWS CLI configured with admin permissions
- GitHub Organization or Repository admin access
- GitHub Personal Access Token (PAT) or GitHub App credentials
- Wiz connected to AWS account for image scanning

---

## Step 1: Prepare EKS Cluster

```bash
# Verify cluster is running
kubectl get nodes

# Verify OIDC provider is enabled (required for IRSA)
aws eks describe-cluster --name <cluster-name> \
  --query "cluster.identity.oidc.issuer" --output text

# If OIDC not enabled, associate it
eksctl utils associate-iam-oidc-provider \
  --cluster <cluster-name> \
  --approve
```

---

## Step 2: Create Namespaces

```bash
# Dedicated namespace for runners
kubectl create namespace arc-runners

# Namespace for ARC controller
kubectl create namespace arc-system
```

---

## Step 3: Set Up IRSA (IAM Roles for Service Accounts)

```bash
# Get OIDC issuer URL
OIDC_URL=$(aws eks describe-cluster --name <cluster-name> \
  --query "cluster.identity.oidc.issuer" --output text | sed 's|https://||')

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

Create `trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/<OIDC_URL>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "<OIDC_URL>:sub": "system:serviceaccount:arc-runners:arc-runner-sa",
          "<OIDC_URL>:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

```bash
# Create IAM role
aws iam create-role \
  --role-name GitHubActionsRunnerRole \
  --assume-role-policy-document file://trust-policy.json

# Attach only the policies your pipelines actually need
aws iam attach-role-policy \
  --role-name GitHubActionsRunnerRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

---

## Step 4: Create Service Account with IRSA Annotation

```yaml
# arc-runner-serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: arc-runner-sa
  namespace: arc-runners
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/GitHubActionsRunnerRole
```

```bash
kubectl apply -f arc-runner-serviceaccount.yaml
```

---

## Step 5: Install Actions Runner Controller (ARC) via Helm

```bash
# Add Helm repo
helm repo add actions-runner-controller \
  https://actions-runner-controller.github.io/actions-runner-controller
helm repo update

# Install ARC controller
helm install arc \
  --namespace arc-system \
  --create-namespace \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
```

---

## Step 6: Configure GitHub Authentication

**Option A — GitHub PAT:**

```bash
kubectl create secret generic github-secret \
  --namespace arc-runners \
  --from-literal=github_token=<YOUR_PAT>
```

**Option B — GitHub App (recommended for production):**

```bash
kubectl create secret generic github-app-secret \
  --namespace arc-runners \
  --from-literal=github_app_id=<APP_ID> \
  --from-literal=github_app_installation_id=<INSTALLATION_ID> \
  --from-literal=github_app_private_key="$(cat private-key.pem)"
```

---

## Step 7: Build and Harden Runner Container Image

```dockerfile
# Dockerfile
FROM ghcr.io/actions/actions-runner:latest

USER root

# Remove unnecessary packages
RUN apt-get remove -y telnet ftp \
  && apt-get autoremove -y \
  && apt-get clean

USER runner
```

```bash
# Build and push to ECR
aws ecr get-login-password --region <region> | \
  docker login --username AWS \
  --password-stdin <ACCOUNT_ID>.dkr.ecr.<region>.amazonaws.com

docker build -t github-actions-runner:hardened .

docker tag github-actions-runner:hardened \
  <ACCOUNT_ID>.dkr.ecr.<region>.amazonaws.com/github-actions-runner:hardened

docker push \
  <ACCOUNT_ID>.dkr.ecr.<region>.amazonaws.com/github-actions-runner:hardened
```

---

## Step 8: Scan Runner Image with Wiz

```bash
# Wiz CLI scan — must pass before deployment
wizcli docker scan \
  --image <ACCOUNT_ID>.dkr.ecr.<region>.amazonaws.com/github-actions-runner:hardened \
  --policy "Block Critical and High" \
  --output json > wiz-scan-results.json

# Check result — must return "pass"
cat wiz-scan-results.json | jq '.result.status'
```

---

## Step 9: Deploy Runner Scale Set with Pod Security

Create `runner-scaleset-values.yaml`:

```yaml
githubConfigUrl: "https://github.com/<org>/<repo>"
githubConfigSecret: github-app-secret

minRunners: 1
maxRunners: 10

containerMode:
  type: kubernetes

template:
  spec:
    serviceAccountName: arc-runner-sa

    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      fsGroup: 1000

    containers:
    - name: runner
      image: <ACCOUNT_ID>.dkr.ecr.<region>.amazonaws.com/github-actions-runner:hardened

      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop: ["ALL"]

      resources:
        requests:
          cpu: "500m"
          memory: "512Mi"
        limits:
          cpu: "2"
          memory: "4Gi"

      volumeMounts:
      - name: tmp
        mountPath: /tmp
      - name: runner-work
        mountPath: /home/runner/_work

    volumes:
    - name: tmp
      emptyDir: {}
    - name: runner-work
      emptyDir: {}
```

```bash
helm install arc-runner-set \
  --namespace arc-runners \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
  -f runner-scaleset-values.yaml
```

---

## Step 10: Apply Network Policies

```yaml
# network-policy-runners.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: runner-egress-policy
  namespace: arc-runners
spec:
  podSelector:
    matchLabels:
      app: arc-runner
  policyTypes:
  - Egress
  - Ingress
  egress:
  - to: []
    ports:
    - port: 443
      protocol: TCP
  ingress: []
```

```bash
kubectl apply -f network-policy-runners.yaml
```

---

## Step 11: Configure Secrets Manager Integration

In your GitHub Actions workflow — no static credentials in environment variables:

```yaml
- name: Get secret from AWS Secrets Manager
  uses: aws-actions/aws-secretsmanager-get-secrets@v1
  with:
    secret-ids: |
      MY_SECRET, arn:aws:secretsmanager:<region>:<account>:secret:my-secret
    parse-json-secrets: true
```

---

## Step 12: Verify End-to-End

```bash
# Check ARC controller is running
kubectl get pods -n arc-system

# Check runner pods are registered
kubectl get pods -n arc-runners

# Check runner logs — should show "Runner registered successfully"
kubectl logs -n arc-runners <runner-pod-name>

# Watch pod lifecycle — spins up, completes job, terminates
kubectl get pods -n arc-runners --watch

# Verify IRSA is working — should return GitHubActionsRunnerRole ARN
kubectl exec -it <runner-pod> -n arc-runners -- \
  aws sts get-caller-identity
```

---

## Step 13: Validate in Wiz

- Navigate to **Wiz → Kubernetes → arc-runners namespace**
- Confirm no privileged containers flagged
- Confirm IRSA annotations detected correctly
- Confirm image scan results linked to running pods
- Check for any runtime anomalies post-deployment

---

## Security Controls Summary

| Control | Implementation |
|---|---|
| Ephemeral runners | Pod deleted after every job |
| Zero static credentials | IRSA via service account annotation |
| Least privilege | Scoped IAM role per runner workload |
| No privilege escalation | `allowPrivilegeEscalation: false` |
| Read-only filesystem | `readOnlyRootFilesystem: true` |
| Dropped capabilities | `capabilities: drop: ALL` |
| Image hardening | Unnecessary packages removed |
| Image scanning | Wiz CLI scan gate before deployment |
| Network restriction | Egress limited to GitHub + AWS APIs only |
| Secrets management | AWS Secrets Manager — no env vars |
| Audit trail | CloudTrail captures all AWS API calls from runners |

---

## Troubleshooting

| Issue | Check |
|---|---|
| Runner not registering | GitHub PAT/App permissions, ARC controller logs |
| IRSA not working | OIDC provider associated, trust policy conditions match namespace/SA |
| Pod failing to start | Pod security context conflicts, resource limits |
| Network policy blocking | Temporarily remove policy, test, re-apply |
| Wiz scan failing | Review CVEs in `wiz-scan-results.json` |
| Secrets not injected | Verify IRSA role has `secretsmanager:GetSecretValue` permission |

---

## References

- [Actions Runner Controller (ARC) — GitHub](https://github.com/actions/actions-runner-controller)
- [IRSA — AWS EKS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [Wiz CLI Documentation](https://docs.wiz.io/wiz-docs/docs/wizcli-overview)
- [Pod Security Standards — Kubernetes](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [AWS Secrets Manager GitHub Action](https://github.com/aws-actions/aws-secretsmanager-get-secrets)
