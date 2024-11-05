

resource "azurerm_route_table" "internet_route_firewall_udr" {
  name                = var.internet_route_firewall_udr.name
  location            = var.internet_route_firewall_udr.location
  resource_group_name = var.internet_route_firewall_udr.resource_group_name

  route {
    name                   = "internet-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_ip_address
  }

}