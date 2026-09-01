output "acr_id" {
  description = "ID of the container registry."
  value       = azurerm_container_registry.this.id
}

output "acr_name" {
  description = "Name of the container registry"
  value       = azurerm_container_registry.this.name
}

output "acr_login_server" {
  description = "Login server hostname for the registry - used later for push/pull and pipeline tasks."
  value       = azurerm_container_registry.this.login_server
}