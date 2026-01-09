#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../.env" ]; then
  source "$SCRIPT_DIR/../.env"
else
  echo -e "${RED}Error: .env file not found in $SCRIPT_DIR${NC}"
  echo -e "${YELLOW}Please create a .env file based on .env.example${NC}"
  exit 1
fi

if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo -e "${RED}Error: GITHUB_USERNAME and GITHUB_TOKEN must be set in .env file${NC}"
  exit 1
fi

if [ -n "$1" ]; then
  NAMESPACE="$1"
  echo -e "${GREEN}Using namespace: ${NAMESPACE}${NC}"
else
  echo -e "${YELLOW}Enter the namespace:${NC}"
  read -r NAMESPACE

  if [ -z "$NAMESPACE" ]; then
    echo -e "${RED}Error: Namespace cannot be empty${NC}"
    exit 1
  fi
fi

if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
  echo -e "${YELLOW}Namespace '${NAMESPACE}' does not exist. Creating it...${NC}"
  kubectl create namespace "$NAMESPACE"
  echo -e "${GREEN}Namespace '${NAMESPACE}' created successfully!${NC}"
else
  echo -e "${GREEN}Namespace '${NAMESPACE}' already exists.${NC}"
fi

echo -e "${GREEN}Creating GitHub Container Registry secret for namespace: ${NAMESPACE}...${NC}"

kubectl delete secret docker-registry ghcr-registry -n "$NAMESPACE" --ignore-not-found=true
kubectl create secret docker-registry ghcr-registry \
  --docker-server=https://ghcr.io \
  --docker-username="$GITHUB_USERNAME" \
  --docker-password="$GITHUB_TOKEN" \
  --namespace="$NAMESPACE"

echo -e "${GREEN}GitHub Container Registry secret created successfully in namespace '${NAMESPACE}'!${NC}"
