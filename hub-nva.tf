locals {
    prefix-hub-nva         = "hub-nva"
    hub-nva-location       = "eastus"
    hub-nva-resource-group = "hub-nva-rg"
}

resource "azurerm_resource_group" "hub-nva-rg" {
    name     = "${local.prefix-hub-nva}-rg"
    location = local.hub-nva-location

    tags = {
    environment = local.prefix-hub-nva
    }
}

resource "azurerm_network_interface" "hub-nva-nic" {
    name                 = "${local.prefix-hub-nva}-nic"
    location             = azurerm_resource_group.hub-nva-rg.location
    resource_group_name  = azurerm_resource_group.hub-nva-rg.name
    enable_ip_forwarding = true

    ip_configuration {
    name                          = local.prefix-hub-nva
    subnet_id                     = azurerm_subnet.hub-dmz.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.3.36"
    }

    tags = {
    environment = local.prefix-hub-nva
    }
}

resource "azurerm_virtual_machine" "hub-nva-vm" {
    name                  = "${local.prefix-hub-nva}-vm"
    location              = azurerm_resource_group.hub-nva-rg.location
    resource_group_name   = azurerm_resource_group.hub-nva-rg.name
    network_interface_ids = [azurerm_network_interface.hub-nva-nic.id]
    vm_size               = var.vmsize

    storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
    }

    storage_os_disk {
    name              = "hubosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    }

    os_profile {
    computer_name  = "${local.prefix-hub-nva}-vm"
    admin_username = var.username
    admin_password = var.password
    }

    os_profile_linux_config {
    disable_password_authentication = false
    }

    tags = {
    environment = local.prefix-hub-nva
    }
}

resource "azurerm_virtual_machine_extension" "enable-routes" {
    name                 = "enable-iptables-routes"
    virtual_machine_id   = azurerm_virtual_machine.hub-nva-vm.id
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.0"


    settings = <<SETTINGS
    {
        "fileUris": [
        "https://raw.githubusercontent.com/mspnp/reference-architectures/master/scripts/linux/enable-ip-forwarding.sh"
        ],
        "commandToExecute": "bash enable-ip-forwarding.sh"
    }
SETTINGS

    tags = {
    environment = local.prefix-hub-nva
    }
}

resource "azurerm_route_table" "hub-gateway-rt" {
    name                          = "hub-gateway-rt"
    location                      = azurerm_resource_group.hub-nva-rg.location
    resource_group_name           = azurerm_resource_group.hub-nva-rg.name
    disable_bgp_route_propagation = false

    route {
    name           = "toHub"
    address_prefix = "10.1.0.0/16"
    next_hop_type  = "VnetLocal"
    }

    route {
    name                   = "togilan"
    address_prefix         = "10.3.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.1.3.36"
    }

    route {
    name                   = "tocore"
    address_prefix         = "10.4.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.1.3.36"
    }

    tags = {
    environment = local.prefix-hub-nva
    }
}

resource "azurerm_subnet_route_table_association" "hub-gateway-rt-hub-vnet-gateway-subnet" {
    subnet_id      = azurerm_subnet.hub-gateway-subnet.id
    route_table_id = azurerm_route_table.hub-gateway-rt.id
    depends_on = [azurerm_subnet.hub-gateway-subnet]
}

resource "azurerm_route_table" "gilan-rt" {
    name                          = "gilan-rt"
    location                      = azurerm_resource_group.hub-nva-rg.location
    resource_group_name           = azurerm_resource_group.hub-nva-rg.name
    disable_bgp_route_propagation = false

    route {
    name                   = "tocore"
    address_prefix         = "10.4.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.1.3.36"
    }

    route {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "vnetlocal"
    }

    tags = {
    environment = local.prefix-hub-nva
    }
}

resource "azurerm_subnet_route_table_association" "gilan-rt-gilan-vnet-mgmt" {
    subnet_id      = azurerm_subnet.gilan-mgmt.id
    route_table_id = azurerm_route_table.gilan-rt.id
    depends_on = [azurerm_subnet.gilan-mgmt]
}

resource "azurerm_subnet_route_table_association" "gilan-rt-gilan-vnet-workload" {
    subnet_id      = azurerm_subnet.gilan-workload.id
    route_table_id = azurerm_route_table.gilan-rt.id
    depends_on = [azurerm_subnet.gilan-workload]
}

resource "azurerm_route_table" "core-rt" {
    name                          = "core-rt"
    location                      = azurerm_resource_group.hub-nva-rg.location
    resource_group_name           = azurerm_resource_group.hub-nva-rg.name
    disable_bgp_route_propagation = false

    route {
    name                   = "togilan"
    address_prefix         = "10.3.0.0/16"
    next_hop_in_ip_address = "10.1.3.36"
    next_hop_type          = "VirtualAppliance"
    }

    route {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "vnetlocal"
    }

    tags = {
    environment = local.prefix-hub-nva
    }
}

resource "azurerm_subnet_route_table_association" "core-rt-core-vnet-mgmt" {
    subnet_id      = azurerm_subnet.core-mgmt.id
    route_table_id = azurerm_route_table.core-rt.id
    depends_on = [azurerm_subnet.core-mgmt]
}

resource "azurerm_subnet_route_table_association" "core-rt-core-vnet-workload" {
    subnet_id      = azurerm_subnet.core-workload.id
    route_table_id = azurerm_route_table.core-rt.id
    depends_on = [azurerm_subnet.core-workload]
}
