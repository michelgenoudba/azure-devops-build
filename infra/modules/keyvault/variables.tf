variable "resource_group_name" {
  description = "Name of the existing resource group to deploy the Key Vault into."
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault."
  type        = string
}

variable "name" {
  description = "Globally unique name for the Key Vault (3-24 characters, alphanumeric and hyphens)."
  type        = string
}

variable "sku_name" {
  description = "SKU for the Key Vault: standard or premium (HSM-backed)."
  type        = string
  default     = "standard"
}

variable "purge_protection_enabled" {
  description = "Whether purge protection is enabled. False by default for this dev-focused project — see ADR 0004."
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Days deleted vaults/items are retained (7-90). Minimum kept as default per ADR 0004."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags applied to the Key Vault."
  type        = map(string)
  default     = {}
}

variable "allowed_ip_ranges" {
  description = "Public IPs/CIDRs allowed to reach the Key Vault data plane. Supply via a local, gitignored tfvars file — never hardcode a real IP into a committed file."
  type        = list(string)
  default     = []
}

