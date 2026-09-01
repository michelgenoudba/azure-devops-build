variable "resource_group_name" {
  description = "Name of the existing resource group to deploy AKS into."
  type        = string
}

variable "location" {
  description = "Azure region for the AKS cluster."
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix used to form the cluster's API server FQDN."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to pin. Leave null to use AKS's current default GA version."
  type        = string
  default     = null
}

variable "vnet_subnet_id" {
  description = "Subnet ID for Azure CNI pod/node networking (snet-aks from the networking module)."
  type        = string
}

variable "system_node_vm_size" {
  description = "VM size for the system node pool."
  type        = string
  default     = "Standard_D2s_v4"
}

variable "system_node_count" {
  description = "Node count for the system node pool (fixed, no autoscaler for this dev scaffold)."
  type        = number
  default     = 1
}

variable "user_node_vm_size" {
  description = "VM size for the user (application) node pool."
  type        = string
  default     = "Standard_D2s_v4"
}

variable "user_node_count" {
  description = "Node count for the user node pool (fixed, no autoscaler for this dev scaffold)."
  type        = number
  default     = 1
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace for Container Insights (from the log-analytics module)."
  type        = string
}

variable "tags" {
  description = "Tags applied to the cluster and node pools."
  type        = map(string)
  default     = {}
}

variable "service_cidr" {
  description = "CIDR for Kubernetes Service (ClusterIP) addresses. Must not overlap the VNet or any subnet — virtual, never actually routed on the VNet."
  type        = string
  default     = "10.100.0.0/16"
}

variable "dns_service_ip" {
  description = "IP within service_cidr used for the cluster's internal DNS service."
  type        = string
  default     = "10.100.0.10"
}