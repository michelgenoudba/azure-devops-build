data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku_name
  rbac_authorization_enabled = true
  purge_protection_enabled   = var.purge_protection_enabled # tfsec:ignore:azure-keyvault-no-purge — see ADR 0004
  soft_delete_retention_days = var.soft_delete_retention_days

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ip_ranges
  }

  tags = var.tags
}


