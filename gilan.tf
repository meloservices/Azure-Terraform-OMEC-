
locals {
    gilan-location       = "eastus"
    gilan-resource-group = "gilan-vnet-rg"
    prefix-gilan         = "gilan"
}

resource "azurerm_resource_group" "gilan-vnet-rg" {
    name     = local.gilan-resource-group
    location = local.gilan-location
}

resource "azurerm_virtual_network" "gilan-vnet" {
    name                = "gilan-vnet"
    location            = azurerm_resource_group.gilan-vnet-rg.location
    resource_group_name = azurerm_resource_group.gilan-vnet-rg.name
    address_space       = ["10.3.0.0/16"]

    tags = {
    environment = local.prefix-gilan
    }
}

resource "azurerm_subnet" "gilan-mgmt" {
    name                 = "mgmt"
    resource_group_name  = azurerm_resource_group.gilan-vnet-rg.name
    virtual_network_name = azurerm_virtual_network.gilan-vnet.name
    address_prefixes     = ["10.3.1.0/24"]
}

resource "azurerm_subnet" "gilan-workload" {
    name                 = "workload"
    resource_group_name  = azurerm_resource_group.gilan-vnet-rg.name
    virtual_network_name = azurerm_virtual_network.gilan-vnet.name
    address_prefixes     = ["10.3.3.0/24"]
}

resource "azurerm_virtual_network_peering" "gilan-hub-peer" {
    name                      = "gilan-hub-peer"
    resource_group_name       = azurerm_resource_group.gilan-vnet-rg.name
    virtual_network_name      = azurerm_virtual_network.gilan-vnet.name
    remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id

    allow_virtual_network_access = true
    allow_forwarded_traffic = true
    allow_gateway_transit   = false
    use_remote_gateways     = true
    depends_on = [azurerm_virtual_network.gilan-vnet, azurerm_virtual_network.hub-vnet , azurerm_virtual_network_gateway.hub-vnet-gateway]
}

resource "azurerm_network_interface" "gilan-nic" {
    name                 = "${local.prefix-gilan}-nic"
    location             = azurerm_resource_group.gilan-vnet-rg.location
    resource_group_name  = azurerm_resource_group.gilan-vnet-rg.name
    enable_ip_forwarding = true
    enable_accelerated_networking = true

    ip_configuration {
    name                          = local.prefix-gilan
    subnet_id                     = azurerm_subnet.gilan-mgmt.id
    private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_virtual_machine" "gilan-vm" {
    name                  = "${local.prefix-gilan}-vm"
    location              = azurerm_resource_group.gilan-vnet-rg.location
    resource_group_name   = azurerm_resource_group.gilan-vnet-rg.name
    network_interface_ids = [azurerm_network_interface.gilan-nic.id]
    vm_size               = "Standard_DS3_v2"

    storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
    }

    storage_os_disk {
    name              = "gilandisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    }

    os_profile {
    computer_name  = "${local.prefix-gilan}-vm"
    admin_username = var.username
    admin_password = var.password
    custom_data    = base64encode(data.template_file.linux-vm-cloud-init.rendered)
    }

    os_profile_linux_config {
    disable_password_authentication = false
    }

    tags = {
    environment = local.prefix-gilan
    }
}

 

resource "azurerm_virtual_network_peering" "hub-gilan-peer" {
    name                      = "hub-gilan-peer"
    resource_group_name       = azurerm_resource_group.hub-vnet-rg.name
    virtual_network_name      = azurerm_virtual_network.hub-vnet.name
    remote_virtual_network_id = azurerm_virtual_network.gilan-vnet.id
    allow_virtual_network_access = true
    allow_forwarded_traffic   = true
    allow_gateway_transit     = true
    use_remote_gateways       = false
    depends_on = [azurerm_virtual_network.gilan-vnet, azurerm_virtual_network.hub-vnet, azurerm_virtual_network_gateway.hub-vnet-gateway]
}
