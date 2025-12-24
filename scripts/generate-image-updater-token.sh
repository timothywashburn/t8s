#!/bin/bash
set -e

# Check if secret exists and has a valid token
if kubectl get secret argocd-image-updater-secret -n argocd &>/dev/null; then
  EXISTING_TOKEN=$(kubectl get secret argocd-image-updater-secret -n argocd -o jsonpath='{.data.argocd\.token}' | base64 -d)
  if [ -n "$EXISTING_TOKEN" ]; then
    echo "Secret already exists with valid token"
    exit 10
  fi
fi

ARGOCD_IP=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.spec.clusterIP}')
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)

# Get admin session token
RESPONSE=$(curl -sk -X POST http://$ARGOCD_IP/api/v1/session \
  -d "{\"username\":\"admin\",\"password\":\"$ARGOCD_PASS\"}" \
  -H "Content-Type: application/json")

ADMIN_TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# Generate token for image-updater account
TOKEN_RESPONSE=$(curl -sk -X POST http://$ARGOCD_IP/api/v1/account/image-updater/token \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"image-updater-token"}')

IMAGE_UPDATER_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# Create the secret
kubectl create secret generic argocd-image-updater-secret \
  --from-literal=argocd.token=$IMAGE_UPDATER_TOKEN \
  --namespace argocd \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secret created successfully"
