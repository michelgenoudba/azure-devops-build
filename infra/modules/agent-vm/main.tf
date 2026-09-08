resource "azurerm_network_security_group" "this" {
    name                = "nsg-agent-vm"
    resource_group_name = var.resource_group_name
    location            = var.location
    tags                = var.tags
}

# Without this, the NSG falls back to Azure's default deny-all-inbound rule and SSH
# times out from every source, including trusted ones. Scoped to the same IPs already
# trusted for Key Vault/AKS data-plane access rather than opened to the whole internet.
resource "azurerm_network_security_rule" "allow_ssh" {
    count                       = length(var.allowed_ip_ranges) > 0 ? 1 : 0
    name                        = "AllowSSHInbound"
    priority                    = 100
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefixes     = var.allowed_ip_ranges
    destination_address_prefix  = "*"
    resource_group_name         = var.resource_group_name
    network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_public_ip" "this" {
    name                = "pip-agent-vm"
    resource_group_name = var.resource_group_name
    location            = var.location
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = var.tags
}

resource "azurerm_network_interface" "this" {
    name                = "nic-agent-vm"
    resource_group_name = var.resource_group_name
    location            = var.location

    ip_configuration {
        name                          = "internal"
        subnet_id                     = var.subnet_id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.this.id 
    }

    tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "this" {
    network_interface_id      = azurerm_network_interface.this.id
    network_security_group_id = azurerm_network_security_group.this.id 
}

resource "tls_private_key" "ssh" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "this" {
    name                  = "vm-agent-dev"
    resource_group_name   = var.resource_group_name
    location              = var.location
    size                  = var.vm_size
    zone                  = var.zone
    admin_username        = var.admin_username
    network_interface_ids = [
        azurerm_network_interface.this.id,
    ]

    disable_password_authentication = true
    admin_ssh_key {
        username   = var.admin_username
        public_key = tls_private_key.ssh.public_key_openssh 
    }

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
    }

    tags = var.tags
}

resource "azurerm_key_vault_secret" "agent_vm_ssh_private_key" {
    name              = "agent-vm-ssh-private-key"
    value             = tls_private_key.ssh.private_key_pem
    key_vault_id      = var.key_vault_id
}
