variable "resource_group_name" {
  description = "Name of the existing resource group to deploy the workspace into."
  type        = string
}

variable "location" {
  description = "Azure region for the Log Analytics workspace."
  type        = string
}

variable "name" {
  description = "Name of the Log Analytics workspace."
  type        = string
}

variable "sku" {
  description = "Pricing tier for the workspace."
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Data retention period in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to the workspace."
  type        = map(string)
  default     = {}
}