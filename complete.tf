provider "azurerm" {
  features {}
  subscription_id = "72bf37f0-5fb1-4e9a-b847-4b60657009a2"  # Reemplaza con tu ID de suscripción
}

# Grupo de recursos
resource "azurerm_resource_group" "sampleVpn_rg" {
  name     = "sampleVpn-RG"
  location = "East US"  # Cambia a la región que desees
}

# Red virtual
resource "azurerm_virtual_network" "sampleVpn_vnet" {
  name                = "sampleVpn-vnet"
  location            = azurerm_resource_group.sampleVpn_rg.location
  resource_group_name = azurerm_resource_group.sampleVpn_rg.name
  address_space       = ["10.0.0.0/16"]  # Cambia la red virtual según sea necesario
}

# Subred GatewaySubnet
resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.sampleVpn_rg.name
  virtual_network_name = azurerm_virtual_network.sampleVpn_vnet.name
  address_prefixes     = ["10.0.255.0/27"]  # Subred para el gateway VPN
}

# IP pública estática para el VNG
resource "azurerm_public_ip" "sampleVpn_ip" {
  name                = "sampleVpn-ip"
  location            = azurerm_resource_group.sampleVpn_rg.location
  resource_group_name = azurerm_resource_group.sampleVpn_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"  # Utiliza SKU estándar para VPN
}

# Local Network Gateway (representando la red local)
resource "azurerm_local_network_gateway" "sampleVpn_lng" {
  name                = "sampleVpn-lng"
  location            = azurerm_resource_group.sampleVpn_rg.location
  resource_group_name = azurerm_resource_group.sampleVpn_rg.name
  gateway_ip_address  = "200.0.67.5"  # Dirección IP pública del gateway local
  address_space       = ["192.168.69.250/32"]  # Espacio de direcciones de la red local
}

# Virtual Network Gateway (VNG)
resource "azurerm_virtual_network_gateway" "sampleVpn_vng" {
  name                = "sampleVpn-vng"
  location            = azurerm_resource_group.sampleVpn_rg.location
  resource_group_name = azurerm_resource_group.sampleVpn_rg.name
  type                = "Vpn"
  vpn_type            = "RouteBased"  # Usamos RouteBased para la conexión
  sku                 = "VpnGw1"  # SKU adecuado para VNG

  ip_configuration {
    name                          = "gateway-ip-config"
    public_ip_address_id          = azurerm_public_ip.sampleVpn_ip.id  # Asociar la IP pública
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.255.4"  # Dirección IP privada del VNG
    subnet_id                     = azurerm_subnet.gateway_subnet.id  # Subred GatewaySubnet
  }
}

# Crear la conexión VPN entre VNG y LNG
resource "azurerm_virtual_network_gateway_connection" "sampleVpn_connection" {
  name                                = "sampleVpn-connection"
  resource_group_name                 = azurerm_resource_group.sampleVpn_rg.name
  location                            = azurerm_resource_group.sampleVpn_rg.location
  virtual_network_gateway_id         = azurerm_virtual_network_gateway.sampleVpn_vng.id
  local_network_gateway_id           = azurerm_local_network_gateway.sampleVpn_lng.id
  connection_type                    = "IPsec"  # Tipo de conexión IPsec
  shared_key                          = "S1cC3cDfa5t"  # Shared PSK

  # Configuración de IKE Phase 1
  ike_policy {
    encryption_algorithm     = "AES256"
    integrity_algorithm      = "SHA256"
    dh_group                 = 14
    lifetime_sec             = 28800  # Tiempo de vida de la fase 1
  }

  # Configuración de IKE Phase 2
  ipsec_policy {
    encryption_algorithm     = "AES256"
    integrity_algorithm      = "SHA256"
    dh_group                 = 14  # PFS Group 14
    lifetime_sec             = 3600  # Tiempo de vida de la fase 2
  }
}

