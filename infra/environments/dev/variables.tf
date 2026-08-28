variable "allowed_ip_ranges" {
  description = "Public IPs/CIDRs allowed to reach dev Key Vault data plane."
  type        = list(string)
  default     = []
}
