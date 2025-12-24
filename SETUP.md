# Setup Instructions

This document provides step-by-step instructions for setting up the infrastructure on a fresh K3s cluster.

## Prerequisites

- kubectl installed locally
- Helmfile installed locally
- Ansible installed locally

## Step 1: Ansible System Configuration and K3s Setup

Edit `ansible/inventory.ini` with your server IP and SSH user:

```ini
[control_plane]
control-plane ansible_host=YOUR_VPS_IP ansible_user=YOUR_SSH_USER

[workers]
# Uncomment and add worker nodes if needed
# worker-1 ansible_host=192.168.1.101 ansible_user=root
```

Test connectivity:

```bash
cd ansible/
ansible all -m ping
```

Run the playbook:

```bash
ansible-playbook setup-k3s.yml
```

## Step 2: Configure Local kubectl Access

Setup local access to use `kubectl`. The following script can do so automatically but requires the control plane to be accessible at a public ip, and have a ssh server accessible via public key (no password auth) at port 22.

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

Restart K3s by running the following from the control plane (recommended to fix known port-forwarding issue):
```bash
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

- Accessible at host defined in `config.yaml`
- Username: `admin`
- Password: (from below command)
```bash
kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d
```

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