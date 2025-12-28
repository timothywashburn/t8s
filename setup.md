# Setup

## Prerequisites

- Ansible installed locally
- kubectl installed locally
- Helmfile installed locally
- autossh installed locally

## Instructions

### Step 1: Cluster Configuration

Copy the following files:
* `clusters/example.ini` → `clusters/default.ini`
* `clusters/example.yaml` → `clusters/default.yaml`

Fill out the `.ini` file with details about your control plane and worker nodes (if any), and fill out the `.yaml` file with cluster settings and projects.

### Step 2: DNS Configuration

Point DNS records to the `load_balancer_ip` specified in the config.

Example A Records:
- `argo.example.com` → `load_balancer_ip`
- `k8s.example.com` → `load_balancer_ip`
- `grafana.example.com` → `load_balancer_ip`
- `longhorn.example.com` → `load_balancer_ip`

### Step 3: Cluster Setup

Test if ansible can connect to the servers (ssh into each vps before to verify their host keys):

```bash
ansible -i clusters/default.ini all -m ping
```

Run the playbook to set up K3s:

```bash
ansible-playbook -i clusters/default.ini ansible/setup-k3s.yml
```

### Step 4: Configure Local kubectl Access

Port forward the api to your local machine if necessary using:

```bash
autossh -M 0 -fN -L <local_port>:localhost:6443 <username@host>
```

Setup local access to use `kubectl`. The following script can do so automatically but requires the control plane to be accessible at a public ip, and have a ssh server accessible via public key (no password auth) at port 22.

```bash
./scripts/setup-kubeconfig.sh USER@VPS_IP CONTEXT_NAME
```

### Step 5: Install dependencies

Install the project dependencies via:

```bash
CLUSTER=default helmfile sync
```

### Step 6: Configure dependencies

Configure the project dependencies via:

```bash
ansible-playbook -i clusters/default.ini ansible/configure-infrastructure.yml
```

# Post-Setup

## Setup Authentik

Follow the [setup-authentik.md](setup-authentik.md) instructions to set up access to Authentik and establish a secure way to access the project's Longhorn dashboard.

## Adding Additional Projects

Once the setup has been completed, adding projects is easy. Simply edit the application properties and run:
```bash
CLUSTER=default helmfile apply
```