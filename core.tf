locals {
    core-location       = "eastus"
    core-resource-group = "core-vnet-rg"
    prefix-core         = "core"
}

resource "azurerm_resource_group" "core-vnet-rg" {
    name     = local.core-resource-group
    location = local.core-location
}

resource "azurerm_virtual_network" "core-vnet" {
    name                = "${local.prefix-core}-vnet"
    location            = azurerm_resource_group.core-vnet-rg.location
    resource_group_name = azurerm_resource_group.core-vnet-rg.name
    address_space       = ["10.4.0.0/16"]

    tags = {
    environment = local.prefix-core
    }
}

resource "azurerm_subnet" "core-mgmt" {
    name                 = "mgmt"
    resource_group_name  = azurerm_resource_group.core-vnet-rg.name
    virtual_network_name = azurerm_virtual_network.core-vnet.name
    address_prefixes     = ["10.4.1.0/24"]
}


resource "azurerm_subnet" "core-workload" {
    name                 = "workload"
    resource_group_name  = azurerm_resource_group.core-vnet-rg.name
    virtual_network_name = azurerm_virtual_network.core-vnet.name
    address_prefixes     = ["10.4.2.0/24"]
}


resource "azurerm_virtual_network_peering" "core-hub-peer" {
    name                      = "${local.prefix-core}-hub-peer"
    resource_group_name       = azurerm_resource_group.core-vnet-rg.name
    virtual_network_name      = azurerm_virtual_network.core-vnet.name
    remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id

    allow_virtual_network_access = true
    allow_forwarded_traffic = true
    allow_gateway_transit   = false
    use_remote_gateways     = true
    depends_on = [azurerm_virtual_network.core-vnet, azurerm_virtual_network.hub-vnet, azurerm_virtual_network_gateway.hub-vnet-gateway]
}

resource "azurerm_network_interface" "core-nic" {
    name                 = "${local.prefix-core}-nic"
    location             = azurerm_resource_group.core-vnet-rg.location
    resource_group_name  = azurerm_resource_group.core-vnet-rg.name
    enable_ip_forwarding = true

    ip_configuration {
    name                          = local.prefix-core
    subnet_id                     = azurerm_subnet.core-mgmt.id
    private_ip_address_allocation = "Dynamic"
    }

    tags = {
    environment = local.prefix-core
    }
}

resource "azurerm_virtual_machine" "core-vm" {
    name                  = "${local.prefix-core}-vm"
    location              = azurerm_resource_group.core-vnet-rg.location
    resource_group_name   = azurerm_resource_group.core-vnet-rg.name
    network_interface_ids = [azurerm_network_interface.core-nic.id]
    vm_size               = "Standard_DS3_v2"

    storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
    }

    storage_os_disk {
    name              = "coreosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    }

    os_profile {
    computer_name  = "${local.prefix-core}-vm"
    admin_username = "azureuser"
    admin_password = "Password123!"
    }

    os_profile_linux_config {
    disable_password_authentication = false
    }

    tags = {
    environment = local.prefix-core
    }
}


resource "azurerm_virtual_network_peering" "hub-core-peer" {
    name                      = "hub-core-peer"
    resource_group_name       = azurerm_resource_group.hub-vnet-rg.name
    virtual_network_name      = azurerm_virtual_network.hub-vnet.name
    remote_virtual_network_id = azurerm_virtual_network.core-vnet.id
    allow_virtual_network_access = true
    allow_forwarded_traffic   = true
    allow_gateway_transit     = true
    use_remote_gateways       = false
    depends_on = [azurerm_virtual_network.core-vnet, azurerm_virtual_network.hub-vnet, azurerm_virtual_network_gateway.hub-vnet-gateway]
}
