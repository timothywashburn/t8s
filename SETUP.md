# Setup Instructions

This document provides step-by-step instructions for setting up the infrastructure on a fresh K3s cluster.

## Prerequisites

- kubectl installed locally
- Helmfile installed locally

## Step 1: Install K3s and Configure System

### Control Plane Install

```bash
# SSH into VPS
curl -sfL https://get.k3s.io | sh -

# Configure system limits for monitoring workloads
echo 'fs.inotify.max_user_instances = 8192' | sudo tee -a /etc/sysctl.conf > /dev/null
echo 'fs.inotify.max_user_watches = 524288' | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sysctl -p
```

### Worker Node Install (if applicable)

Fetch the control plane's K3S_TOKEN from `/var/lib/rancher/k3s/server/node-token` and then run the following with the appropriate url and token:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://myserver:6443 K3S_TOKEN=MYTOKEN sh -
```

To verify you can run `sudo k3s kubectl get nodes`.

## Step 2: Configure Local kubectl Access

Setup local access to use `kubectl`. The following script is unreliable but can help.

[//]: # (doesn't work with ports/didn't work with wiji's server at all)
```bash
./scripts/setup-kubeconfig.sh USER@VPS_IP CONTEXT_NAME
```

## Step 3: Install Infrastructure Components

Copy `config.example.yaml` → `config.yaml` and input desired values.

Use Helmfile to install the core infrastructure components:

```bash
helmfile sync
```

If there are port-forward networking issues after the sync, restart k3s:

```bash
# SSH into VPS
sudo systemctl restart k3s
```

## Step 4: DNS Configuration

Point DNS records to cluster's external IP based on the hosts set in `config.yaml`.

Example A Records:
- `argo.timothyw.dev` → `EXTERNAL_IP`
- `k8s.timothyw.dev` → `EXTERNAL_IP`
- `grafana.timothyw.dev` → `EXTERNAL_IP`

## Step 5: Access Services

### ArgoCD

- Accessible at host defined in `config.yaml`
- Username: `admin`
- Password: (from below command)

**Initial ArgoCD Password:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Kubernetes Dashboard

- Accessible at host defined in `config.yaml`
- Token: (from below command)

**Kubernetes Admin Token:**
```bash
kubectl get secret admin-user-token -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d
```

### Grafana

### Grafana

- Accessible at host defined in `config.yaml`
- Username: `admin`
- Password: `adminadminadmin` ⚠️ **Change this default password for production use**

**Getting Started with Grafana:**
1. Go to **Explore** → **Prometheus** for metrics queries
2. Go to **Explore** → **Loki** for log queries

**Example Prometheus Queries:**
```promql
# Show all targets
up

# CPU usage by pod
rate(container_cpu_usage_seconds_total[5m])

# Memory usage
container_memory_usage_bytes

# Kubernetes pod status
kube_pod_info
```

**Example Loki Queries:**
```logql
# Monitoring namespace logs
{namespace="monitoring"}

# ArgoCD logs
{namespace="argocd"}

# Error logs from monitoring namespace
{namespace="monitoring"} |= "error"

# All logs containing "restart"
{namespace="monitoring"} |= "restart"
```

## Step 6: Configure ArgoCD Image Updater

The ArgoCD Image Updater is installed automatically. To complete the setup:

1. **Generate API token via ArgoCD Web UI**:
   - Navigate to **Settings** → **Accounts**
   - Find the `image-updater` account
   - Click **Generate Token**
   - Copy the generated token

2. **Create the token secret**:
   ```bash
   kubectl create secret generic argocd-image-updater-secret \
     --from-literal argocd.token=$YOUR_TOKEN \
     --namespace argocd
   ```

[//]: # (I still need to figure out what this means this wording is confusing)
3. **Apply additional RBAC permissions**:
   ```bash
   helmfile apply
   ```