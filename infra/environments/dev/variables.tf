variable "allowed_ip_ranges" {
  description = "Public IPs/CIDRs allowed to reach dev Key Vault data plane."
  type        = list(string)
  default     = []
}

variable "app_namespace" {
  description = "Kubernetes namespace the app's ServiceAccount lives in."
  type        = string
  default     = "app"
}

variable "app_service_account_name" {
  description = "Kubernetes ServiceAccount name federated to the app's Azure identity."
  type        = string
  default     = "app-sa"
}

variable "agent_vm_zone" {
  description = "Availability zone to try for the agent VM (\"1\", \"2\", \"3\") — Standard_B2s hit a capacity restriction with no zone set, so this lets us retry per-zone without editing code each time."
  type        = string
  default     = "1"
}

variable "agent_vm_size" {
  description = "Agent VM size. Standard_B2s hit SkuNotAvailable (capacity restriction) in Switzerland North across every zone, so this defaults to Standard_D2s_v3 — a mainstream size with confirmed quota (Standard DSv3 Family: 10 vCPUs, 0 used) and much broader regional availability."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "pipeline_service_principal_object_id" {
  description = "Object ID of the sc-azure-devops-build service connection's service principal — granted Kubernetes-level Azure RBAC access on the AKS cluster so the CD pipeline can run kubectl/helm against it."
  type        = string
}

variable "maintainer_object_id" {
  description = "Object ID of the human maintainer's own Azure AD identity — granted standing Cluster Admin (AKS) and Secrets Officer (Key Vault) independent of whichever identity is currently running Terraform."
  type        = string
}

variable "alert_notification_email" {
  description = "Email address that receives Azure Monitor alert notifications."
  type        = string
}