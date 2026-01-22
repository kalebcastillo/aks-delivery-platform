terraform {
  backend "azurerm" {
    resource_group_name  = "aks-delivery-platform"
    storage_account_name = "kalebtfstate"
    container_name       = "tfstate"
    key                 = "aks-delivery-platform.terraform.tfstate"
  }
}

