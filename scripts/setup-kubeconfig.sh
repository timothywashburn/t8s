#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get CONNECTION_STRING (USER@IP)
if [ -n "$1" ]; then
  CONNECTION_STRING="$1"
  echo -e "${GREEN}Using connection string: ${CONNECTION_STRING}${NC}"
else
  echo -e "${YELLOW}Enter the connection string (USER@IP):${NC}"
  read -r CONNECTION_STRING

  if [ -z "$CONNECTION_STRING" ]; then
    echo -e "${RED}Error: Connection string cannot be empty${NC}"
    exit 1
  fi
fi

if [[ ! "$CONNECTION_STRING" =~ ^([^@]+)@(.+)$ ]]; then
    echo -e "${RED}Error: Invalid connection string format. Use USER@IP${NC}"
    exit 1
fi
VPS_USER="${BASH_REMATCH[1]}"
VPS_IP="${BASH_REMATCH[2]}"

# Get CONTEXT_NAME
if [ -n "$2" ]; then
  CONTEXT_NAME="$2"
  echo -e "${GREEN}Using context name: ${CONTEXT_NAME}${NC}"
else
  echo -e "${YELLOW}Enter the context name:${NC}"
  read -r CONTEXT_NAME

  if [ -z "$CONTEXT_NAME" ]; then
    echo -e "${RED}Error: Context name cannot be empty${NC}"
    exit 1
  fi
fi

# Get PORT (optional, defaults to 6443)
if [ -n "$3" ]; then
  PORT="$3"
  echo -e "${GREEN}Using port: ${PORT}${NC}"
else
  echo -e "${YELLOW}Enter the port (press Enter for default 6443):${NC}"
  read -r PORT

  if [ -z "$PORT" ]; then
    PORT="6443"
    echo -e "${GREEN}Using default port: ${PORT}${NC}"
  fi
fi

if [[ -f ~/.kube/config ]]; then
    echo -e "${YELLOW}Backing up existing kubeconfig${NC}"
    cp ~/.kube/config ~/.kube/config.backup."$(date +%Y-%m-%d_%H-%M-%S)"
fi

echo -e "${BLUE}Setting up kubectl access to K3s cluster at $VPS_IP as context '$CONTEXT_NAME'${NC}"
mkdir -p ~/.kube
ssh "$CONNECTION_STRING" "sudo cat /etc/rancher/k3s/k3s.yaml" > /tmp/k3s-config.yaml

echo -e "${BLUE}Extracting certificates${NC}"
CA_DATA=$(grep 'certificate-authority-data:' /tmp/k3s-config.yaml | awk '{print $2}')
CLIENT_CERT_DATA=$(grep 'client-certificate-data:' /tmp/k3s-config.yaml | awk '{print $2}')
CLIENT_KEY_DATA=$(grep 'client-key-data:' /tmp/k3s-config.yaml | awk '{print $2}')
echo "$CA_DATA" | base64 -d > /tmp/ca.crt
echo "$CLIENT_CERT_DATA" | base64 -d > /tmp/client.crt
echo "$CLIENT_KEY_DATA" | base64 -d > /tmp/client.key

echo -e "${BLUE}Adding new context to kubeconfig${NC}"
kubectl config set-cluster "$CONTEXT_NAME" \
  --server=https://127.0.0.1:${PORT} \
  --certificate-authority=/tmp/ca.crt \
  --embed-certs=true
kubectl config set-credentials "$CONTEXT_NAME" \
  --client-certificate=/tmp/client.crt \
  --client-key=/tmp/client.key \
  --embed-certs=true
kubectl config set-context "$CONTEXT_NAME" \
  --cluster="$CONTEXT_NAME" \
  --user="$CONTEXT_NAME"

rm -f /tmp/k3s-config.yaml /tmp/ca.crt /tmp/client.crt /tmp/client.key

kubectl config use-context "$CONTEXT_NAME"

echo -e "${BLUE}Testing connection${NC}"
if kubectl get nodes; then
    echo -e "${GREEN}Successfully configured kubectl access to K3s cluster!${NC}"
    echo -e "${GREEN}Current context: $(kubectl config current-context)${NC}"
else
    echo -e "${RED}Failed to connect to cluster. Check your connection and SSH access.${NC}"
    exit 1
fi