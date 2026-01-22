# Main Terraform entrypoint for AKS Delivery Platform

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.2"
  name     = var.resource_group_name
  location = var.location
  enable_telemetry = true
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.17"
  name                = var.vnet_name
  location            = var.location
  parent_id           = module.resource_group.resource_id
  address_space       = [var.vnet_address_space]
  enable_telemetry    = true
}

module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "~> 0.3"
  name                = var.aks_name
  location            = var.location
  resource_group_name = module.resource_group.name
  dns_prefix          = var.aks_dns_prefix
  managed_identities = {
    system_assigned = true
  }
  azure_active_directory_role_based_access_control = {
    tenant_id              = var.aad_tenant_id
    admin_group_object_ids = [var.aad_admin_object_id]
    azure_rbac_enabled     = true
  }
  default_node_pool = {
    name       = "nodepool1"
    node_count = var.aks_node_count
    vm_size    = var.aks_node_vm_size
    enable_auto_scaling = false
    os_disk_size_gb = 30
    type = "VirtualMachineScaleSets"
    orchestrator_version = null
    mode = "System"
    enable_node_public_ip = false
    enable_host_encryption = false
    enable_spot_vm = var.aks_enable_spot
    spot_max_price = var.aks_spot_max_price
  }
  network_profile = {
    network_plugin = "azure"
    network_policy = "azure"
    load_balancer_sku = "standard"
  }
  enable_telemetry = true
}

# Optional: Azure Container Registry (comment out if using Docker Hub)
# module "acr" {
#   source  = "Azure/avm-res-azurerm-container-registry/azurerm"
#   version = "~> 1.0"
#   name                = var.acr_name
#   location            = var.location
#   resource_group_name = module.resource_group.name
#   sku                 = "Basic"
#   enable_telemetry    = true
# }

# ArgoCD and GitOps setup is automated via: ./bootstrap.sh
# This deploys the Helm chart and bootstraps the Application CR

