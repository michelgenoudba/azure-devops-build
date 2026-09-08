variable "resource_group_name" {
    type = string
}

variable "location" {
    type = string
}

variable "subnet_id" {
    description = "Subnet the agent VM's NIC attaches to."
    type = string
}

variable "key_vault_id" {
    description = "Key Vault to store the generated SSH private key in."
    type        = string
}

variable "vm_size" {
    type    = string
    default = "Standard_B2s"
}

variable "zone" {
    description = "Availability zone to pin the VM to (\"1\", \"2\", \"3\"). Null lets Azure place it with no zone preference."
    type    = string
    default = null
}

variable "admin_username" {
    type    = string
    default = "azureuser"
}

variable "tags" {
    type    = map(string)
    default = {}
}

variable "allowed_ip_ranges" {
    description = "Public IPs/CIDRs allowed to SSH into the agent VM (port 22). Empty list leaves the NSG at its default deny-all-inbound."
    type    = list(string)
    default = []
}
