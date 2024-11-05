

variable "internet_route_firewall_udr" {
  description = "路由表的基本信息"
  type = object({
    name                = string
    location            = string
    resource_group_name = string
  })
}

variable "firewall_ip_address" {
  description = "防火墙的私有 IP 地址，用于作为路由的下一跳 IP 地址"
  type        = string
}
