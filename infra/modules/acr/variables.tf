variable "resource_group_name" {
  description = "Name of the existing resource group to deploy the container registry into."
  type        = string
}

variable "location" {
  description = "Azure region for the container registry."
  type        = string
}

variable "name" {
  description = "Globally unique name for the container registry (alphanumeric only, 5-50 characters)."
  type        = string
}

variable "sku" {
  description = "SKU tier for the registry: Basic, Standard, or Premium."
  type        = string
  default     = "Basic"
}

variable "admin_enabled" {
  description = "Whether to enable the built-in admin account (shared username/password). Kept false by default — access should go through Azure AD identities and RBAC role assignments instead, consistent with the no-stored-secrets approach from phase 00."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the registry."
  type        = map(string)
  default     = {}
}