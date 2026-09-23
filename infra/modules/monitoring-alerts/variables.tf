variable "resource_group_name" {
  description = "Resource group the alert rules and action group are created in."
  type        = string
}

variable "location" {
  description = "Azure region for the alert rules and action group."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace the scheduled query rules run against."
  type        = string
}

variable "action_group_name" {
  description = "Name of the Azure Monitor action group used to notify on alert fire."
  type        = string
}

variable "action_group_short_name" {
  description = "Short name (<12 chars) for the action group , shown in SMS/notifications."
  type        = string
}

variable "notification_email" {
  description = "Email address that receives alert notifications."
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
}