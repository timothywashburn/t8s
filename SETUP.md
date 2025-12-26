# Setup Instructions

## Prerequisites

- Ansible installed locally
- kubectl installed locally
- Helmfile installed locally

## Step 1: Cluster Configuration

Copy the following files:
* `clusters/example.ini` → `clusters/default.ini`
* `clusters/example.yaml` → `clusters/default.yaml`

Fill out the `.ini` file with details about your control plane and worker nodes (if any), and fill out the `.yaml` file with cluster settings and projects.

## Step 2: DNS Configuration

Point DNS records to the `loadBalancerIP` specified in the config.

Example A Records:
- `argo.example.com` → `loadBalancerIP`
- `k8s.example.com` → `loadBalancerIP`
- `grafana.example.com` → `loadBalancerIP`
- `longhorn.example.com` → `loadBalancerIP`


## Step 3: Cluster Setup

Test if ansible can connect to the servers:

```bash
ansible -i clusters/default.ini all -m ping
```

Run the playbook to set up K3s:

```bash
ansible-playbook -i clusters/default.ini ansible/setup-k3s.yml
```

## Step 4: Configure Local kubectl Access

Port forward the api to your local machine if necessary using:

```bash
autossh -M 0 -fN -L <local_port>:localhost:6443 <username@host>
```

Setup local access to use `kubectl`. The following script can do so automatically but requires the control plane to be accessible at a public ip, and have a ssh server accessible via public key (no password auth) at port 22.

```bash
./scripts/setup-kubeconfig.sh USER@VPS_IP CONTEXT_NAME
```

## Step 5: Install dependencies

Install the project dependencies via:

```bash
CLUSTER=default helmfile sync
```

## Step 6: Configure dependencies

Configure the project dependencies via:

```bash
ansible-playbook -i clusters/default.ini ansible/configure-infrastructure.yml
```