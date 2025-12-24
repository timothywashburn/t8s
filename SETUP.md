# Setup Instructions

## Prerequisites

- Ansible installed locally

## Step 1: System Configuration and Setup

Edit `ansible/inventory.ini` with your server IP and SSH user:

```ini
[control_plane]
control-plane ansible_host=YOUR_VPS_IP ansible_user=YOUR_SSH_USER

[workers]
# Uncomment and add worker nodes as needed
# worker-1 ansible_host=192.168.1.101 ansible_user=root
```

Test connectivity:

```bash
cd ansible/
ansible all -m ping
```

Run the playbook:

```bash
ansible-playbook site.yml
```

## Step 2: DNS Configuration

Point DNS records to cluster's external IP based on the hosts set in `config.yaml`.

Example A Records:
- `argo.timothyw.dev` → `EXTERNAL_IP`
- `k8s.timothyw.dev` → `EXTERNAL_IP`
- `grafana.timothyw.dev` → `EXTERNAL_IP`


## Step 3 (OPTIONAL): Configure Local kubectl Access

Setup local access to use `kubectl`. The following script can do so automatically but requires the control plane to be accessible at a public ip, and have a ssh server accessible via public key (no password auth) at port 22.

[//]: # (doesn't work with ports/didn't work with wiji's server at all)
```bash
./scripts/setup-kubeconfig.sh USER@VPS_IP CONTEXT_NAME
```