output "id" {
  description = "Resource ID of the Log Analytics workspace — used later to wire AKS Container Insights."
  value       = azurerm_log_analytics_workspace.this.id
}

output "name" {
  description = "Name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.name
}