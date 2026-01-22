#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Read admin object ID and subscription ID from terraform.tfvars
ADMIN_OBJECT_ID=$(grep "aad_admin_object_id" "$PROJECT_DIR/terraform/terraform.tfvars" | awk -F'"' '{print $2}')
SUBSCRIPTION_ID=$(grep "subscription_id" "$PROJECT_DIR/terraform/terraform.tfvars" | awk -F'"' '{print $2}')

cd "$PROJECT_DIR/terraform"
terraform init
terraform apply -auto-approve

# Assign Azure RBAC role
az role assignment create \
  --assignee "$ADMIN_OBJECT_ID" \
  --role "Azure Kubernetes Service RBAC Cluster Admin" \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourcegroups/aks-delivery-platform/providers/Microsoft.ContainerService/managedClusters/aks-delivery || true

az aks get-credentials --resource-group aks-delivery-platform --name aks-delivery --overwrite-existing || true

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace --version 7.3.0 --wait

kubectl apply -f "$PROJECT_DIR/k8s/argocd-application.yaml"

echo ""
echo "✓ Bootstrap complete!"



