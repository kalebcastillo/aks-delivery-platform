# AKS Delivery Platform Bootstrap

Complete one-command deployment of AKS infrastructure with GitOps.

## Quick Start

```bash
./bootstrap.sh
```

This script automatically:
1. Deploys Terraform infrastructure (RG, VNet, AKS)
2. Configures kubectl credentials
3. Deploys ArgoCD via Helm
4. Bootstraps GitOps by applying the ArgoCD Application CR

## What Gets Deployed

- Azure Resource Group
- Virtual Network (10.0.0.0/16)
- AKS Cluster with:
  - Azure AD RBAC enabled
  - System-assigned managed identity
  - Azure CNI networking
- ArgoCD watching `k8s/` folder on GitHub

## Post-Deployment

After bootstrap completes, all manifests in `k8s/` folder are automatically synced by ArgoCD.

To view ArgoCD UI:
```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

## Configuration

Edit `terraform/terraform.tfvars` to customize:
- Resource names
- Azure region
- Node pool size
- Azure AD admin object ID

## Cleanup

```bash
cd terraform
terraform destroy
```

## Security Notes

- Local accounts are disabled on the cluster (AAD RBAC only)
- All sensitive values stored in `terraform.tfvars` (gitignored)
- Service principal for Terraform auth stored in tfvars
