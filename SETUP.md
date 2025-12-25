# Setup Instructions

## Prerequisites

- Ansible installed locally

## Step 1: System Configuration and Setup

Copy `ansible/inventory.example.ini` to `ansible/inventory.ini` and add your server IP and SSH user:

Test connectivity:

```bash
cd ansible/
ansible all -m ping
```

Run the playbook to set up K3s:

```bash
ansible-playbook setup-k3s.yml
```

## Step 2: Configure Local kubectl Access

Setup local access to use `kubectl`. The following script can do so automatically but requires the control plane to be accessible at a public ip, and have a ssh server accessible via public key (no password auth) at port 22.

[//]: # (doesn't work with ports/didn't work with wiji's server at all)
```bash
./scripts/setup-kubeconfig.sh USER@VPS_IP CONTEXT_NAME
```

## Step 3: Infrastructure Configuration and Setup

Copy `config.example.yaml` to `config.yaml` and fill out configuration. The 

## Step 2: DNS Configuration

Point DNS records to cluster's external IP based on the hosts set in `config.yaml`.

Example A Records:
- `argo.timothyw.dev` → `EXTERNAL_IP`
- `k8s.timothyw.dev` → `EXTERNAL_IP`
- `grafana.timothyw.dev` → `EXTERNAL_IP`
