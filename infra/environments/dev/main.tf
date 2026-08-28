data "azurerm_resource_group" "main" {
  name = "rg-azure-devops-build"
}

module "networking" {
  source = "../../modules/networking"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  vnet_name           = "vnet-azure-devops-build-dev"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "snet-aks" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "snet-services" = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }

  tags = {
    project     = "azure-devops-build"
    environment = "dev"
  }
}

module "acr" {
  source = "../../modules/acr"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "acrazuredevopsbuildmg"
  sku                 = "Basic"

  tags = {
    project     = "azure-devops-build"
    environment = "dev"
  }
}

module "keyvault" {
  source = "../../modules/keyvault"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "kv-azure-devops-build-mg"
  allowed_ip_ranges   = var.allowed_ip_ranges

  tags = {
    project     = "azure-devops-build"
    environment = "dev"
  }
}

module "log_analytics" {
  source = "../../modules/log-analytics"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "law-azure-devops-build-mg"

  tags = {
    project     = "azure-devops-build"
    environment = "dev"
  }
}