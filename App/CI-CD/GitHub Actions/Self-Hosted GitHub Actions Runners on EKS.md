# GitHub Actions Self-Hosted Runners on EKS with ARC

This document describes how to run GitHub Actions jobs on ephemeral pods in an Amazon EKS cluster using Actions Runner Controller (ARC) in runner scale set mode.

**Result:** when a workflow is triggered (manually or automatically), ARC starts a runner pod in the cluster, the pod runs the job, and the pod is deleted when the job finishes. No runner pods run while idle.

## Environment used

| Item | Value |
|---|---|
| Cluster | Existing EKS Auto Mode cluster |
| Region | `us-east-2` (Ohio) |
| Controller namespace | `arc-systems` |
| Runner namespace | `default` |
| ARC chart version | `0.15.1` (both charts) |
| GitHub authentication | GitHub App |
| Kubernetes secret | `arc-github-secret` |
| Runner scale set name | `eks-arc-runners` (used in `runs-on`) |
| Scope | Repository-level runners |

## Status of each part

| Part | Status |
|---|---|
| Controller install (Step 3) | Done, chart `0.15.1` deployed |
| Runner scale set + workflow without Docker (Steps 4 to 6) | Tested and working |
| Docker builds with `containerMode: dind` (Step 7) | Configuration documented, not yet confirmed as working |

## How it works

1. The **controller** (in `arc-systems`) watches for runner scale sets.
2. Each scale set gets a **listener** pod (in `arc-systems`) that holds a connection to GitHub and waits for jobs.
3. When a job targets `runs-on: eks-arc-runners`, the listener asks the controller for a runner.
4. The controller creates an **ephemeral runner pod** in `default`. EKS Auto Mode launches a node if none has capacity.
5. The pod registers with GitHub, runs one job, and is deleted.

## Prerequisites

- `kubectl`, `helm` (v3) and the AWS CLI on the machine you run commands from
- Access to the EKS cluster (an access entry for your IAM principal)
- Admin access to the GitHub repository (to create and install a GitHub App)
- Outbound internet from the cluster nodes (through a NAT gateway) to `github.com`, `api.github.com`, `*.actions.githubusercontent.com` and `ghcr.io`

---

## Step 1. Connect to the cluster

```bash
aws eks update-kubeconfig --region us-east-2 --name <cluster-name>
kubectl get nodepools
helm version
```

`kubectl get nodes` may show few or no nodes. EKS Auto Mode launches nodes only when pods need them.

## Step 2. Create a GitHub App and the Kubernetes secret

### 2.1 Create the app

1. Go to **Settings → Developer settings → GitHub Apps → New GitHub App**.
   For an organization: **Org → Settings → Developer settings → GitHub Apps**.
2. Fill in:
   - **GitHub App name:** a unique name, for example `eks-arc-runner-poc`
   - **Homepage URL:** any valid URL, such as the repo URL
   - **Webhook:** uncheck **Active**
3. Under **Repository permissions**, set:
   - **Administration:** Read and write
   - **Metadata:** Read-only
4. Under **Where can this GitHub App be installed?**, choose **Only on this account**.
5. Click **Create GitHub App**.

For organization-level runners, also set **Organization permissions → Self-hosted runners: Read and write**.

### 2.2 Collect the three values

| Value | Where to find it |
|---|---|
| App ID | The app's **General** page |
| Private key (`.pem`) | **General → Private keys → Generate a private key** (downloads a file) |
| Installation ID | Click **Install App**, install on the target repo (**Only select repositories**). The number at the end of the resulting URL, `.../settings/installations/<ID>` |

### 2.3 Create the secret

The secret must be in the same namespace as the runner scale set (`default`).

```bash
kubectl create secret generic arc-github-secret \
  --namespace=default \
  --from-literal=github_app_id=<APP_ID> \
  --from-literal=github_app_installation_id=<INSTALLATION_ID> \
  --from-file=github_app_private_key=/path/to/private-key.pem
```

Verify that it has three keys:

```bash
kubectl describe secret arc-github-secret -n default
```

Never commit the `.pem` file to a repository.

## Step 3. Install the ARC controller

```bash
helm install arc \
  --namespace arc-systems --create-namespace \
  --version 0.15.1 \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
```

Expected output includes `STATUS: deployed`. Then check the pod:

```bash
kubectl get pods -n arc-systems
```

The controller pod should show `1/1 Running`. It can stay `Pending` for a minute or two while Auto Mode launches a node.

## Step 4. Create `values.yaml`

```yaml
githubConfigUrl: "https://github.com/<owner>/<repo>"
githubConfigSecret: arc-github-secret

minRunners: 0          # no pods while idle
maxRunners: 5          # upper limit on concurrent runners

template:
  spec:
    containers:
      - name: runner
        image: ghcr.io/actions/actions-runner:latest
        command: ["/home/runner/run.sh"]
        resources:
          requests:
            cpu: "1"
            memory: 2Gi
          limits:
            memory: 4Gi
```

Set resource requests. EKS Auto Mode sizes new nodes from pod requests.

## Step 5. Install the runner scale set

Use the same chart version as the controller.

```bash
helm install eks-arc-runners \
  --namespace default \
  --version 0.15.1 \
  -f values.yaml \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

Verify:

```bash
helm list -A
kubectl get pods -n arc-systems
```

A listener pod (name ending in `-listener`) should be `Running` in `arc-systems`. In GitHub, the runner scale set appears under **Repo → Settings → Actions → Runners**.

## Step 6. Run a test workflow

Create `.github/workflows/arc-test.yml`:

```yaml
name: ARC test
on:
  workflow_dispatch:

jobs:
  test:
    runs-on: eks-arc-runners
    steps:
      - uses: actions/checkout@v4
      - run: |
          echo "Running in pod: $HOSTNAME"
          uname -a
```

Watch the pod lifecycle in a terminal, then trigger the workflow from the **Actions** tab:

```bash
kubectl get pods -n default -w
```

Expected sequence: the runner pod appears as `Pending`, moves to `Running`, executes the job, and is deleted.

To use the runners in an existing workflow, change `runs-on: self-hosted` (or `ubuntu-latest`) to `runs-on: eks-arc-runners`.

## Step 7. Enable Docker builds (dind mode)

> **Status:** not yet confirmed as working in this environment. Verify with the test below before relying on it.

The default runner pod has no Docker daemon. Steps such as `docker build`, or container actions such as `snyk/actions/docker`, fail with:

```
failed to connect to the docker API at unix:///var/run/docker.sock
```

### 7.1 Update `values.yaml`

Remove the `template:` block and add `containerMode`:

```yaml
githubConfigUrl: "https://github.com/<owner>/<repo>"
githubConfigSecret: arc-github-secret

minRunners: 0
maxRunners: 5

containerMode:
  type: "dind"
```

### 7.2 Apply the change

```bash
helm upgrade eks-arc-runners \
  --namespace default \
  --version 0.15.1 \
  -f values.yaml \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

### 7.3 Test

```yaml
name: Docker test
on: workflow_dispatch
jobs:
  test:
    runs-on: eks-arc-runners
    steps:
      - run: |
          docker version
          docker run --rm hello-world
```

The runner pod should now show `2/2` containers (`runner` and `dind`), and `docker version` should print both Client and Server sections.

The dind container runs as privileged. If the pod stays at `1/2`, check:

```bash
kubectl describe pod <runner-pod> -n default
kubectl logs <runner-pod> -n default -c dind
```

## Troubleshooting

| Symptom | Likely cause | Check |
|---|---|---|
| Job stuck at "Waiting for a runner" | `runs-on` does not match the Helm release name | `helm list -n default` |
| Listener pod missing or logs show 401/403 | Wrong App ID, Installation ID or key; app not installed on the repo | `kubectl logs -n arc-systems <listener-pod>` |
| Runner pod stuck `Pending` | Node cannot be launched, or no resource requests | `kubectl describe pod <pod> -n default` |
| `ImagePullBackOff` on the runner image | No outbound path to `ghcr.io` | NAT gateway and route tables |
| Secret not found | Secret is in a different namespace than the scale set | `kubectl get secret -n default` |
| `docker.sock` connection error | Runner has no Docker daemon | Apply Step 7 |
| Docker Hub `429 Too Many Requests` | Anonymous pull rate limit on the NAT IP | Log in to Docker Hub in the workflow, or pull base images from ECR |

## Security notes

- Do not run workflows from fork pull requests on these runners in a public repository. Untrusted code would execute inside the cluster.
- dind mode uses privileged pods. Limit it to trusted repositories and branches.
- Keep the GitHub App installed only on the repositories that need it.
- For AWS access in jobs, use GitHub OIDC with `aws-actions/configure-aws-credentials` instead of static keys.

## Upgrade

`helm upgrade` does not update ARC's CRDs. To move to a new ARC version:

1. Uninstall all runner scale sets, then the controller.
2. Delete the ARC CRDs (`kubectl get crd | grep actions.github.com`).
3. Reinstall the controller and scale sets with the new `--version`.

## Cleanup

```bash
helm uninstall eks-arc-runners -n default
helm uninstall arc -n arc-systems
kubectl delete secret arc-github-secret -n default
kubectl delete namespace arc-systems
```

Then delete the GitHub App (or its private key) in GitHub.

## References

- [Deploying runner scale sets with ARC](https://docs.github.com/en/actions/how-tos/manage-runners/use-actions-runner-controller/deploy-runner-scale-sets)
- [Authenticating ARC to the GitHub API](https://docs.github.com/en/actions/how-tos/manage-runners/use-actions-runner-controller/authenticate-to-the-api)
- [Create a storage class (EKS Auto Mode)](https://docs.aws.amazon.com/eks/latest/userguide/create-storage-class.html)
