provider "azurerm" {
  features {}
  subscription_id = "72bf37f0-5fb1-4e9a-b847-4b60657009a2"
}

resource "azurerm_resource_group" "existing" {
  name     = "ClaroPayEcCalidad"
  location = "East US"
}

data "azurerm_virtual_network" "existing_vnet" {
  name                = "vnet-df-calidad"
  resource_group_name = azurerm_resource_group.existing.name
}

data "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
  resource_group_name  = azurerm_resource_group.existing.name
}

data "azurerm_public_ip" "existing_public_ip" {
  name                = "paymovil-datafast-ip"
  resource_group_name = azurerm_resource_group.existing.name
}

resource "azurerm_virtual_network_gateway" "standard_gateway" {
  name                = "paymovil-datafast-qa-vpn"
  location            = azurerm_resource_group.existing.location
  resource_group_name = azurerm_resource_group.existing.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  active_active       = false
  enable_bgp          = false

  ip_configuration {
    name                          = "gateway-ip-config"
    public_ip_address_id          = data.azurerm_public_ip.existing_public_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.gateway_subnet.id
  }
}

resource "azurerm_local_network_gateway" "paymovil_datafast_calidad" {
  name                = "Paymovil-Datafast-Calidad"
  location            = azurerm_resource_group.existing.location
  resource_group_name = azurerm_resource_group.existing.name
  gateway_address     = "200.0.67.5"
  address_space       = ["192.168.69.250/32"]
}

resource "azurerm_virtual_network_gateway_connection" "vng_to_lng_connection" {
  name                       = "paymovil-datafast-qa-connection"
  location                   = azurerm_resource_group.existing.location
  resource_group_name        = azurerm_resource_group.existing.name
  virtual_network_gateway_id = azurerm_virtual_network_gateway.standard_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.paymovil_datafast_calidad.id
  shared_key                 = "S1cC3cDfa5t"
  type                       = "IPsec"

  enable_bgp                        = false
  use_policy_based_traffic_selectors = false
}

