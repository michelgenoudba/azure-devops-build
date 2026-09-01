output "vnet_id" {
  value = module.networking.vnet_id
}

output "subnet_ids" {
  value = module.networking.subnet_ids
}

output "acr_login_server" {
  value = module.acr.acr_login_server
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "log_analytics_workspace_id" {
  value = module.log_analytics.id
}

output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "aks_oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}

