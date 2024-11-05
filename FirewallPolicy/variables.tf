

variable "firewall_policy" {
  type = object({
    name                = string
    resource_group_name = string
    location            = string
    proxy_enabled       = optional(bool, false)      # 是否启用 DNS 代理，默认值为 false
    dns_servers         = optional(list(string), []) # 自定义 DNS 服务器列表，默认为空
  })
}
