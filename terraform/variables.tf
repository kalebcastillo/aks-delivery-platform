variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
  sensitive   = true
}

variable "terraform_sp_client_id" {
  description = "Service principal client ID for Terraform Kubernetes provider."
  type        = string
  sensitive   = true
}

variable "terraform_sp_client_secret" {
  description = "Service principal client secret for Terraform Kubernetes provider."
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
  default     = "aks-delivery-platform"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "vnet_name" {
  description = "Name of the Virtual Network."
  type        = string
  default     = "aks-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the VNet."
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_name" {
  description = "Name of the AKS cluster."
  type        = string
  default     = "aks-delivery"
}

variable "aks_dns_prefix" {
  description = "DNS prefix for the AKS cluster."
  type        = string
  default     = "aksdelivery"
}

variable "aks_node_count" {
  description = "Number of nodes in the default node pool."
  type        = number
  default     = 1
}

variable "aks_node_vm_size" {
  description = "VM size for AKS nodes."
  type        = string
  default     = "Standard_B2s"
}

variable "aks_enable_spot" {
  description = "Enable spot instances for AKS nodes."
  type        = bool
  default     = true
}

variable "aks_spot_max_price" {
  description = "Max price for spot instances (set to -1 for on-demand)."
  type        = number
  default     = -1
}
variable "aad_tenant_id" {
  description = "Azure AD Tenant ID for AKS RBAC."
  type        = string
  sensitive   = true
}

variable "aad_admin_object_id" {
  description = "Object ID of user/group for AKS cluster admin."
  type        = string
  sensitive   = true
}
variable "acr_name" {
  description = "Name of the Azure Container Registry."
  type        = string
  default     = "akstestacr"
}
