# Main Terraform entrypoint for AKS Delivery Platform

module "resource_group" {
  source  = "Azure/avm-res-azurerm-resource-group/azurerm"
  version = "~> 1.0"
  name     = var.resource_group_name
  location = var.location
  enable_telemetry = true
}

module "vnet" {
  source  = "Azure/avm-res-azurerm-virtual-network/azurerm"
  version = "~> 1.0"
  name                = var.vnet_name
  location            = var.location
  resource_group_name = module.resource_group.name
  address_space       = [var.vnet_address_space]
  enable_telemetry    = true
}

module "aks" {
  source  = "Azure/avm-res-azurerm-kubernetes-cluster/azurerm"
  version = "~> 1.0"
  name                = var.aks_name
  location            = var.location
  resource_group_name = module.resource_group.name
  dns_prefix          = var.aks_dns_prefix
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

output "kube_config" {
  value = module.aks.kube_config
  sensitive = true
}
