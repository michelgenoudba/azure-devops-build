output "vnet_id" {
  value = module.networking.vnet_id
}

output "subnet_ids" {
  value = module.networking.subnet_ids
}

output "acr_login_server" {
  value = module.acr.acr_login_server
}