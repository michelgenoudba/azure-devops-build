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

variable "agent_vm_zone" {
  description = "Availability zone to try for the agent VM (\"1\", \"2\", \"3\") — Standard_B2s hit a capacity restriction with no zone set, so this lets us retry per-zone without editing code each time."
  type        = string
  default     = "1"
}

variable "agent_vm_size" {
  description = "Agent VM size. Standard_B2s hit SkuNotAvailable (capacity restriction) in Switzerland North across every zone, so this defaults to Standard_D2s_v3 — a mainstream size with confirmed quota (Standard DSv3 Family: 10 vCPUs, 0 used) and much broader regional availability."
  type        = string
  default     = "Standard_D2s_v3"
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
