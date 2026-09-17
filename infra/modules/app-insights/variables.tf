variable "resource_group_name" {
  description = "Name of the existing resource group to deploy Application Insights into."
  type        = string
}

variable "location" {
  description = "Azure region for Application Insights."
  type        = string
}

variable "name" {
  description = "Name of the Application Insights resource."
  type        = string
}

variable "workspace_id" {
  description = "Resource ID of the Log Analytics workspace this workspace-based Application Insights resource sends data to."
  type        = string
}

variable "application_type" {
  description = "Type of application being monitored."
  type        = string
  default     = "web"
}

variable "tags" {
  description = "Tags applied to the Application Insights resource."
  type        = map(string)
  default     = {}
}