variable "resource_group_name" {
  description = "Name of the existing resource group to deploy networking resources into."
  type        = string
}

variable "location" {
  description = "Azure region for the networking resources."
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network."
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network, e.g. [\"10.0.0.0/16\"]."
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnets to create. Key is the subnet name, value holds its address prefixes."
  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "tags" {
  description = "Tags applied to all networking resources."
  type        = map(string)
  default     = {}
}
