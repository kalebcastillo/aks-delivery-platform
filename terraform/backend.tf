terraform {
  backend "azurerm" {
    resource_group_name  = "aks-platform-tf-state"
    storage_account_name = "kalebaksterraformstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
