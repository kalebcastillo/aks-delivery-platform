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

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -

# Install controllers without Helm
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Seal local secrets into the manifests (requires .secrets/journal-secret.yaml)
"$SCRIPT_DIR/seal-secrets.sh"

# Apply only the journal-specific ArgoCD Application (not the generic watcher)
kubectl apply -f "$PROJECT_DIR/k8s/argocd-journal-application.yaml"

# Apply monitoring ArgoCD Application
kubectl apply -f "$PROJECT_DIR/k8s/argocd-monitoring-application.yaml"

echo ""
echo "✓ Bootstrap complete!"
echo ""
echo "Access Prometheus (optional):"
echo "  kubectl -n monitoring port-forward svc/prometheus 9090:9090"
echo "  http://localhost:9090"
echo ""
echo "Access Grafana (optional):"
echo "  kubectl -n monitoring port-forward svc/grafana 3000:3000"
echo "  http://localhost:3000"
echo "  Credentials are in k8s/monitoring/manifests/grafana-secret.yaml"




