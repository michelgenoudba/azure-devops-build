data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name            = "system"
    vm_size         = var.system_node_vm_size
    node_count      = var.system_node_count
    vnet_subnet_id  = var.vnet_subnet_id
    os_disk_size_gb = 30    
    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    tenant_id           = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled  = true 
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = var.service_cidr
    dns_service_ip = var.dns_service_ip
  }

  # Enabled now so the cluster doesn't need to be recreated when we wire up
  # federated identity for Key Vault access later in Phase 03.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  upgrade_settings {
    max_surge = "10%"
  }
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_node_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.vnet_subnet_id
  os_disk_size_gb       = 30
  mode                  = "User"

  tags = var.tags
}