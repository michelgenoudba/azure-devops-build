data "azurerm_resource_group" "main" {
  name = "rg-azure-devops-build"
}

data "azurerm_client_config" "current" {}

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

module "aks" {
  source = "../../modules/aks"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  cluster_name        = "aks-azure-devops-build-mg"
  dns_prefix          = "aksazuredevopsbuildmg"

  vnet_subnet_id             = module.networking.subnet_ids["snet-aks"]
  log_analytics_workspace_id = module.log_analytics.id

  tags = {
    project     = "azure-devops-build"
    environment = "dev"
  }
}

# Lets AKS nodes pull images from ACR without any stored credential —
# same least-privilege pattern as the rest of this project.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.acr.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}

resource "azurerm_role_assignment" "aks_rbac_cluster_admin_self" {
  scope                = module.aks.cluster_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}