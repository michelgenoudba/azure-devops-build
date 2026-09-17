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
    "snet-agents" = {
      address_prefixes  = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.KeyVault"]
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
  allowed_subnet_ids  = [module.networking.subnet_ids["snet-agents"]]

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

module "app_insights" {
  source = "../../modules/app-insights"

  resource_group_name = data.azurerm_resource_group.main.name
  location             = data.azurerm_resource_group.main.location
  name                 = "appi-azure-devops-build-mg"
  workspace_id         = module.log_analytics.id

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
  authorized_ip_ranges       = var.allowed_ip_ranges
  tags = {
    project     = "azure-devops-build"
    environment = "dev"
  }
}

module "agent_vm" {
  source = "../../modules/agent-vm"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  subnet_id           = module.networking.subnet_ids["snet-agents"]
  key_vault_id        = module.keyvault.key_vault_id
  vm_size             = var.agent_vm_size
  zone                = var.agent_vm_zone
  allowed_ip_ranges   = var.allowed_ip_ranges

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

resource "azurerm_role_assignment" "aks_rbac_cluster_admin_maintainer" {
  scope                = module.aks.cluster_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.maintainer_object_id
}

resource "azurerm_role_assignment" "aks_rbac_cluster_admin_pipeline" {
  scope                = module.aks.cluster_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.pipeline_service_principal_object_id
}

resource "azurerm_user_assigned_identity" "app_workload" {
  name                = "id-azure-devops-build-app"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  tags = {
    project     = "azure-devops-build"
    environment = "dev"
  }
}

resource "azurerm_federated_identity_credential" "app_workload" {
  name                      = "fic-azure-devops-build-app"
  user_assigned_identity_id = azurerm_user_assigned_identity.app_workload.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = module.aks.oidc_issuer_url
  subject                   = "system:serviceaccount:${var.app_namespace}:${var.app_service_account_name}"
}

resource "azurerm_role_assignment" "app_workload_kv_secrets_user" {
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app_workload.principal_id
}

# Lets this Terraform identity write/read secrets directly (e.g. the test secret
# below) — separate from the AKS workload's own scoped "Secrets User" grant above.
resource "azurerm_role_assignment" "kv_secrets_officer_maintainer" {
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.maintainer_object_id
}

resource "azurerm_role_assignment" "kv_secrets_officer_pipeline" {
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.pipeline_service_principal_object_id
}

# Scratch secret used to verify AKS workload identity end-to-end. Safe to delete
# once that verification is done.
resource "azurerm_key_vault_secret" "workload_identity_test" {
  name         = "workload-identity-test"
  value        = "hello from AKS workload identity"
  key_vault_id = module.keyvault.key_vault_id

    depends_on = [azurerm_role_assignment.kv_secrets_officer_pipeline, azurerm_role_assignment.kv_secrets_officer_maintainer]
}
