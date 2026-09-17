output "connection_string" {
  description = "Connection string used by the Application Insights JavaScript SDK. Not a credential in the traditional sense — it's designed to be embedded in public client-side code — but marked sensitive so it isn't echoed in plain Terraform CLI/CI output by default."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "app_id" {
  description = "Application ID, used when querying Application Insights data via the REST API."
  value       = azurerm_application_insights.this.app_id
}