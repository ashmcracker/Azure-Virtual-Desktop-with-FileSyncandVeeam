variable "project_main_location" {
  type    = string
  default = "eastus"
}



variable "hub_rg" {
  type = object({
    name = string
  })
}

variable "hub_vnet" {
  type = object({
    name          = string
    address_space = list(string)
  })
}

variable "hub_vnet_subnets" {
  type = map(object({
    name             = optional(string)
    address_prefixes = list(string)
  }))
}


variable "jumpvm_subnet_sg" {
  type = object({
    name = string
  })
}

# 安全组规则定义入参
variable "jumpvm_subnet_sg_rules" {
  description = "Map of NSG rules"
  type = map(object({
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
  }))
  default = {}
}


variable "dc_pip" {
  type = object({
    name              = string
    allocation_method = string
  })

  default = {
    name              = "dc_pip"
    allocation_method = "Static"
  }
}



variable "dc_vm" {
  type = object({
    name           = string
    size           = string
    admin_username = string
    admin_password = string
    os_disk = object({
      #None, ReadOnly and ReadWrite
      caching = string
      #Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS
      storage_account_type = string
    })
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
  })
}


variable "pip_vpngw" {
  type = object({
    name              = string
    allocation_method = string
  })
}



variable "hub_vpngw" {
  type = object({
    name     = string
    type     = string
    vpn_type = string
    sku      = string
  })
}


variable "onprem_localgw" {
  type = object({
    name            = string
    gateway_address = string
    address_space   = set(string)
  })
}

variable "gw_connect_1" {
  type = object({
    name       = string
    type       = string
    shared_key = string
  })
  sensitive = true # 标记整个对象为敏感
}



#"fwpl-test-main"
variable "firewall_policy" {
  type = object({
    name                = string
    proxy_enabled       = optional(bool, false)      # 是否启用 DNS 代理，默认值为 false
    dns_servers         = optional(list(string), []) # 自定义 DNS 服务器列表，默认为空
  })
}


variable "pip_firewall" {
  type = object({
    name = string
    allocation_method = string
    sku = string
  })
}


variable "firewall_hub" {
  type = object({
    name = string
    sku_name = string
    sku_tier = string
    ip_configuration_name = string
  })
}













################################################
# AVD Module
################################################

variable "avd_rg" {
  type = object({
    name = string
  })
}


variable "avd_vnet" {
  type = object({
    name          = string
    address_space = list(string)
  })
}

variable "avd_vnet_subnets" {
  type = map(object({
    name             = optional(string)
    address_prefixes = list(string)
  }))
}



variable "avd_subnet_sg" {
  type = object({
    name = string
  })
}


# 安全组规则定义入参
variable "avd_subnet_sg_rules" {
  description = "Map of NSG rules"
  type = map(object({
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
  }))
  default = {}
}


variable "avdfile_subnet_sg" {
  type = object({
    name = string
  })
}


# 安全组规则定义入参
variable "avdfile_subnet_sg_rules" {
  description = "Map of NSG rules"
  type = map(object({
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
  }))
  default = {}
}


variable "avdfile_pe" {
  type = object({
    name = string
    private_service_connection = object({
      name                 = string
      subresource_names    = list(string)
      is_manual_connection = bool
    })

  })
}


# 定义 avd_hostpool_1 变量
variable "avd_hostpool_1" {
  type = object({
    name                     = string
    friendly_name            = optional(string)
    start_vm_on_connect      = bool
    type                     = string
    maximum_sessions_allowed = optional(number)
    load_balancer_type       = optional(string)
  })
}


variable "workspace_1" {
  type = object({
    name          = string
    friendly_name = optional(string) # 可选字段
  })
}


variable "app_group_1" {
  type = object({
    name = string
    type = string # 可选RemoteApp or Desktop
  })
}








################################################
# filebu Module
################################################

variable "filebu_rg" {
  type = object({
    name = string
  })
}


variable "filebu_vnet" {
  type = object({
    name          = string
    address_space = list(string)
  })
}

variable "filebu_vnet_subnets" {
  type = map(object({
    name             = optional(string)
    address_prefixes = list(string)
  }))
}



variable "filebu_subnet_sg" {
  type = object({
    name = string
  })
}


# 安全组规则定义入参
variable "filebu_subnet_sg_rules" {
  description = "Map of NSG rules"
  type = map(object({
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
  }))
  default = {}
}

variable "filebu_storage" {
  type = object({
    name                          = string
    account_tier                  = string
    account_replication_type      = string
    access_tier                   = string
    public_network_access_enabled = bool

  })
}


variable "avdfile_storage" {
  type = object({
    name                          = string
    account_tier                  = string
    account_replication_type      = string
    access_tier                   = string
    public_network_access_enabled = bool

  })
}

variable "filebu_pe" {
  type = object({
    name = string
    private_service_connection = object({
      name                 = string
      subresource_names    = list(string)
      is_manual_connection = bool
    })

  })
}

variable "file_sync_name" {
  type = string
}





################################################
# Veeambu Module
################################################

#veeambu 资源组名字
variable "veeambu_rg" {
  type = object({
    name = string
  })
}

#veeambu 网络
variable "veeambu_vnet" {
  type = object({
    name          = string
    address_space = list(string)
  })
}
#veeambu 子网
variable "veeambu_vnet_subnets" {
  type = map(object({
    name             = optional(string)
    address_prefixes = list(string)
  }))
}


#veeambu 安全组
variable "veeambu_subnet_sg" {
  type = object({
    name = string
  })
}

#veeambu 安全组规则定义入参
variable "veeambu_subnet_sg_rules" {
  description = "Map of NSG rules"
  type = map(object({
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
  }))
  default = {}
}


variable "veeambu_storage" {
  type = object({
    name                          = string
    account_tier                  = string
    account_replication_type      = string
    access_tier                   = string
    public_network_access_enabled = bool

  })
}


variable "veeambu_pe" {
  type = object({
    name = string
    private_service_connection = object({
      name                 = string
      subresource_names    = list(string)
      is_manual_connection = bool
    })

  })
}



################################################
# Peering
################################################


variable "hub_peer_avd_name" {
  type    = string
  default = "peer-hub-avd"
}
variable "avd_peer_hub_name" {
  type    = string
  default = "peer-avd-hub"
}



variable "hub_peer_filebu_name" {
  type    = string
  default = "peer-hub-filebu"
}
variable "filebu_peer_hub_name" {
  type    = string
  default = "peer-filebu-hub"
}




variable "hub_peer_veeambu_name" {
  type    = string
  default = "peer-hub-veeambu"
}
variable "veeambu_peer_hub_name" {
  type    = string
  default = "peer-veeambu-hub"
}



variable "avd_peer_filebu_name" {
  type    = string
  default = "peer-avd-filebu"
}
variable "filebu_peer_avd_name" {
  type    = string
  default = "peer-filebu-avd"
}



################################################
# UDR
################################################



variable "route_table_1" {
  type = object({
    name = string
  })
}