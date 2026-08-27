terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-azure-devops-build"
    storage_account_name = "sttfstatemichelgenoudba"
    container_name        = "tfstate"
    key                   = "dev.terraform.tfstate"
    use_azuread_auth      = true
  }
}