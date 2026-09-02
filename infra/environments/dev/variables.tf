variable "allowed_ip_ranges" {
  description = "Public IPs/CIDRs allowed to reach dev Key Vault data plane."
  type        = list(string)
  default     = []
}

variable "app_namespace" {
  description = "Kubernetes namespace the app's ServiceAccount lives in."
  type        = string
  default     = "app"
}

variable "app_service_account_name" {
  description = "Kubernetes ServiceAccount name federated to the app's Azure identity."
  type        = string
  default     = "app-sa"
}

resource "azurerm_role_assignment" "self_kv_secrets_officer" {
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "workload_identity_test" {
  name         = "workload-identity-test"
  value        = "hello from AKS workload identity"
  key_vault_id = module.keyvault.key_vault_id

  depends_on = [azurerm_role_assignment.self_kv_secrets_officer]
}
