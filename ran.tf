locals {
  onprem-location = "eastus"
  onprem-resource-group = "onprem-vnet-rg"
  prefix-onprem = "onprem"

}

# Create a Resource Group if it doesn’t exist
resource "azurerm_resource_group" "onprem-vnet-rg" {
  name     = local.onprem-resource-group
  location = local.onprem-location
}

# Create ran Virtual Network
resource "azurerm_virtual_network" "ran-vnet" {
  name                = "vran-vnet"
  location            = azurerm_resource_group.onprem-vnet-rg.location
  resource_group_name = azurerm_resource_group.onprem-vnet-rg.name
  address_space       = ["10.2.0.0/16"]

  tags = {
  environment = "vran"
	}
}

# Create subnets
resource "azurerm_subnet" "onprem-mgmt" {
    name                 = "mgmt"
    resource_group_name  = azurerm_resource_group.onprem-vnet-rg.name
    virtual_network_name = azurerm_virtual_network.ran-vnet.name
    address_prefixes = ["10.2.0.0/24"]
  
}

resource "azurerm_subnet" "onprem-gateway-subnet" {
    name                 = "GatewaySubnet"
    resource_group_name  = azurerm_resource_group.onprem-vnet-rg.name
    virtual_network_name = azurerm_virtual_network.ran-vnet.name
    address_prefixes = ["10.2.2.0/24"]
  
}

resource "azurerm_subnet" "onprem-gateway-subnet1" {
    name                 = "Subnet"
    resource_group_name  = azurerm_resource_group.onprem-vnet-rg.name
    virtual_network_name = azurerm_virtual_network.ran-vnet.name
    address_prefixes = ["10.2.5.0/24"]

}


# Create a Public IP
resource "azurerm_public_ip" "ran-access" {
  name                = "ran-access-public-ip"
  location            = azurerm_resource_group.onprem-vnet-rg.location
  resource_group_name = azurerm_resource_group.onprem-vnet-rg.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "vran"
  }
}

resource "azurerm_network_interface" "ran-nic" {
  name                = "ran-nic"
  location            = azurerm_resource_group.onprem-vnet-rg.location
  resource_group_name = azurerm_resource_group.onprem-vnet-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.onprem-gateway-subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_virtual_machine" "ran-vm" {
    name                  = "${local.prefix-onprem}-vm"
    location              = azurerm_resource_group.onprem-vnet-rg.location
    resource_group_name   = azurerm_resource_group.onprem-vnet-rg.name
    network_interface_ids = [azurerm_network_interface.ran-nic.id]
    vm_size               = "Standard_DS3_v2"

    storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
    }

    storage_os_disk {
    name              = "ranosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    }

    os_profile {
    computer_name  = "${local.prefix-onprem}-vm"
    admin_username = "azureuser"
    admin_password = "PasswordHash"
    }

    os_profile_linux_config {
    disable_password_authentication = false
    }


  tags = {
    environment = "vran"
  }
}

resource "azurerm_virtual_machine_extension" "install0" {
  name                 = "install0"
  virtual_machine_id   = azurerm_virtual_machine.ran-vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

 settings = <<SETTINGS
    {
        "fileUris": [
        "https://raw.githubusercontent.com/omec-project/il_trafficgen/master/install.sh"
        ],
        "commandToExecute": "bash install.sh"
    }
SETTINGS
}



resource "azurerm_virtual_network_gateway" "onprem-vpn-gateway"{
        name                 = "onprem-vpn-gateway1"
        location             = azurerm_resource_group.onprem-vnet-rg.location
        resource_group_name  = azurerm_resource_group.onprem-vnet-rg.name

        type                 = "Vpn"
        vpn_type             = "RouteBased"

        active_active        = false
        enable_bgp            = false
        sku                  = "VpnGw1"

        ip_configuration {
        name                 = "vnetGatewayConfig"
        public_ip_address_id = azurerm_public_ip.ran-access.id
        private_ip_address_allocation = "Dynamic"
        subnet_id            = azurerm_subnet.onprem-gateway-subnet.id
        }
        depends_on = [azurerm_public_ip.ran-access]
}

