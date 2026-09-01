output "cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the cluster — sensitive, used to configure kubectl."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL — needed to wire up federated identity credentials later."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Object ID of the auto-created kubelet identity — used to grant AcrPull."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}