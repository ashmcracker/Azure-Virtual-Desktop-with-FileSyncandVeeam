################################################
# HUB Module
################################################

resource "azurerm_resource_group" "hub_rg" {
  name     = var.hub_rg.name
  location = var.project_main_location
}



#创建HUB 虚拟网络
resource "azurerm_virtual_network" "hub_vnet" {
  name                = var.hub_vnet.name
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  address_space       = var.hub_vnet.address_space

  # 子网配置
  subnet {
    name             = "AzureFirewallSubnet"
    address_prefixes = var.hub_vnet_subnets["AzureFirewallSubnet"].address_prefixes
  }

  subnet {
    name             = "GatewaySubnet"
    address_prefixes = var.hub_vnet_subnets["GatewaySubnet"].address_prefixes
  }

  subnet {
    name             = "AzureBastionSubnet"
    address_prefixes = var.hub_vnet_subnets["AzureBastionSubnet"].address_prefixes
  }

  subnet {
    name             = var.hub_vnet_subnets["JumpVMSubnet"].name
    address_prefixes = var.hub_vnet_subnets["JumpVMSubnet"].address_prefixes
  }
}



#创建HUB DC子网的安全组
resource "azurerm_network_security_group" "jumpvm_subnet_sg" {
  name                = var.jumpvm_subnet_sg.name
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
}

# 设置DC子网的安全组规则
resource "azurerm_network_security_rule" "jumpvm_subnet_sg_rules" {
  for_each = var.jumpvm_subnet_sg_rules

  resource_group_name         = azurerm_resource_group.hub_rg.name
  network_security_group_name = azurerm_network_security_group.jumpvm_subnet_sg.name

  name      = each.key
  priority  = each.value.priority
  direction = each.value.direction
  access    = each.value.access
  protocol  = each.value.protocol

  # 源地址
  source_address_prefixes = lookup(each.value, "source_address_prefixes", null)
  source_address_prefix   = lookup(each.value, "source_address_prefixes", null) != null ? null : lookup(each.value, "source_address_prefix", "*")

  # 端口
  source_port_ranges = lookup(each.value, "source_port_ranges", null)
  source_port_range  = lookup(each.value, "source_port_ranges", null) != null ? null : lookup(each.value, "source_port_range", "*")

  # 目标地址
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefixes", null) != null ? null : lookup(each.value, "destination_address_prefix", "*")

  # 目标端口
  destination_port_ranges = lookup(each.value, "destination_port_ranges", null)
  destination_port_range  = lookup(each.value, "destination_port_ranges", null) != null ? null : lookup(each.value, "destination_port_range", "*")
}


# 查询 DC 子网的数据源
data "azurerm_subnet" "JumpVMSubnet" {
  name                 = var.hub_vnet_subnets["JumpVMSubnet"].name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  resource_group_name  = azurerm_resource_group.hub_rg.name
}

# 关联DC子网和安全组
resource "azurerm_subnet_network_security_group_association" "assoc_vnet_sg_1" {
  subnet_id                 = data.azurerm_subnet.JumpVMSubnet.id
  network_security_group_id = azurerm_network_security_group.jumpvm_subnet_sg.id
}






# 创建DC 公网 IP
# resource "azurerm_public_ip" "pip_dc" {
#   name                = var.dc_pip.name
#   resource_group_name = azurerm_resource_group.hub_rg.name
#   location            = azurerm_resource_group.hub_rg.location
#   allocation_method   = var.dc_pip.allocation_method
# }



# 创建DC NIC
resource "azurerm_network_interface" "nic_dc" {
  name                = "nic-test-dc"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.JumpVMSubnet.id # 使用数据源的子网ID
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id          = azurerm_public_ip.pip_dc.id
  }
}


#创建DC
resource "azurerm_windows_virtual_machine" "dc_vm" {
  name                = var.dc_vm.name
  resource_group_name = azurerm_resource_group.hub_rg.name
  location            = azurerm_resource_group.hub_rg.location
  size                = var.dc_vm.size
  admin_username      = var.dc_vm.admin_username
  admin_password      = var.dc_vm.admin_password
  network_interface_ids = [
    azurerm_network_interface.nic_dc.id,
  ]

  os_disk {
    caching              = var.dc_vm.os_disk.caching
    storage_account_type = var.dc_vm.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = var.dc_vm.source_image_reference.publisher
    offer     = var.dc_vm.source_image_reference.offer
    sku       = var.dc_vm.source_image_reference.sku
    version   = var.dc_vm.source_image_reference.version
  }
}



#创建Bastion的公网IP
resource "azurerm_public_ip" "bastion_ip" {
  name                = "bastion_ip"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


# # 查询 AzureBastionSubnet 子网的数据源
data "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  resource_group_name  = azurerm_resource_group.hub_rg.name
}



#创建Bastion
resource "azurerm_bastion_host" "bastion" {
  name                = "bastion"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = data.azurerm_subnet.AzureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}




#创建虚拟网络网关的公网IP
resource "azurerm_public_ip" "pip_vpngw" {
  name                = var.pip_vpngw.name
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  allocation_method   = var.pip_vpngw.allocation_method
}

# # 查询 GatewaySubnet 子网的数据源
data "azurerm_subnet" "GatewaySubnet" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  resource_group_name  = azurerm_resource_group.hub_rg.name
}


#创建hub的虚拟网络网关
resource "azurerm_virtual_network_gateway" "hub_vpngw" {
  name                = var.hub_vpngw.name
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name

  type     = var.hub_vpngw.type
  vpn_type = var.hub_vpngw.vpn_type

  active_active = false
  enable_bgp    = false
  sku           = var.hub_vpngw.sku

  ip_configuration {
    name                          = azurerm_public_ip.pip_vpngw.name
    public_ip_address_id          = azurerm_public_ip.pip_vpngw.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.GatewaySubnet.id
  }

}

#创建Local gateway
resource "azurerm_local_network_gateway" "onprem_localgw" {
  name                = var.onprem_localgw.name
  resource_group_name = azurerm_resource_group.hub_rg.name
  location            = azurerm_resource_group.hub_rg.location
  gateway_address     = var.onprem_localgw.gateway_address
  address_space       = var.onprem_localgw.address_space
}


#创建第一条S2S 隧道链接
resource "azurerm_virtual_network_gateway_connection" "gw_connect_1" {
  name                = var.gw_connect_1.name
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name

  type                       = var.gw_connect_1.type
  virtual_network_gateway_id = azurerm_virtual_network_gateway.hub_vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.onprem_localgw.id

  shared_key = var.gw_connect_1.shared_key
}




#调用防火墙策略模块，创建防火墙策略
module "firewall_policy" {
  source = "./FirewallPolicy"
  firewall_policy = {
    name = var.firewall_policy.name
    resource_group_name  = azurerm_resource_group.hub_rg.name
    location            = azurerm_resource_group.hub_rg.location
    proxy_enabled = var.firewall_policy.proxy_enabled
    dns_servers = var.firewall_policy.dns_servers
  }
}



# 查询 GatewaySubnet 子网的数据源
data "azurerm_subnet" "AzureFirewallSubnet" {
  name                 = "AzureFirewallSubnet"
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  resource_group_name  = azurerm_resource_group.hub_rg.name
}


#创建防火墙的公网IP
resource "azurerm_public_ip" "pip_firewall" {
  name                = var.pip_firewall.name
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  allocation_method   = var.pip_firewall.allocation_method
  sku                 = var.pip_firewall.sku
}

#创建hub的防火墙
resource "azurerm_firewall" "firewall_hub" {
  name                = var.firewall_hub.name
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  sku_name            = var.firewall_hub.sku_name
  sku_tier            = var.firewall_hub.sku_tier
  firewall_policy_id = module.firewall_policy.firewall_policy_id

  ip_configuration {
    name                 = var.firewall_hub.ip_configuration_name
    subnet_id            = data.azurerm_subnet.AzureFirewallSubnet.id
    public_ip_address_id = azurerm_public_ip.pip_firewall.id
  }
}








################################################
# AVD Module
################################################



#创建AVD资源组
resource "azurerm_resource_group" "avd_rg" {
  name     = var.avd_rg.name
  location = var.project_main_location
}



#创建AVD 虚拟网络
resource "azurerm_virtual_network" "avd_vnet" {
  name                = var.avd_vnet.name
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  address_space       = var.avd_vnet.address_space

  subnet {
    name             = var.avd_vnet_subnets["AVDSubnet"].name
    address_prefixes = var.avd_vnet_subnets["AVDSubnet"].address_prefixes
    security_group   = azurerm_network_security_group.avd_subnet_sg.id
  }


  subnet {
    name             = var.avd_vnet_subnets["AVDfileSubnet"].name
    address_prefixes = var.avd_vnet_subnets["AVDfileSubnet"].address_prefixes
    security_group   = azurerm_network_security_group.avdfile_subnet_sg.id
  }

}


#创建AVD 子网的安全组
resource "azurerm_network_security_group" "avd_subnet_sg" {
  name                = var.avd_subnet_sg.name
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name

}

#创建AVD 子网的安全组规则
resource "azurerm_network_security_rule" "avd_subnet_sg_rules" {
  for_each = var.avd_subnet_sg_rules

  resource_group_name         = azurerm_resource_group.avd_rg.name
  network_security_group_name = azurerm_network_security_group.avd_subnet_sg.name

  name      = each.key
  priority  = each.value.priority
  direction = each.value.direction
  access    = each.value.access
  protocol  = each.value.protocol

  # 源地址
  source_address_prefixes = lookup(each.value, "source_address_prefixes", null)
  source_address_prefix   = lookup(each.value, "source_address_prefixes", null) != null ? null : lookup(each.value, "source_address_prefix", "*")

  # 端口
  source_port_ranges = lookup(each.value, "source_port_ranges", null)
  source_port_range  = lookup(each.value, "source_port_ranges", null) != null ? null : lookup(each.value, "source_port_range", "*")

  # 目标地址
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefixes", null) != null ? null : lookup(each.value, "destination_address_prefix", "*")

  # 目标端口
  destination_port_ranges = lookup(each.value, "destination_port_ranges", null)
  destination_port_range  = lookup(each.value, "destination_port_ranges", null) != null ? null : lookup(each.value, "destination_port_range", "*")
}




#创建 avdfile子网安全组
resource "azurerm_network_security_group" "avdfile_subnet_sg" {
  name                = var.avdfile_subnet_sg.name
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name

}



# 创建 avdfile子网安全组规则
resource "azurerm_network_security_rule" "avdfile_subnet_sg_rules" {
  for_each = var.avdfile_subnet_sg_rules

  resource_group_name         = azurerm_resource_group.avd_rg.name
  network_security_group_name = azurerm_network_security_group.avdfile_subnet_sg.name

  name      = each.key
  priority  = each.value.priority
  direction = each.value.direction
  access    = each.value.access
  protocol  = each.value.protocol

  # 源地址
  source_address_prefixes = lookup(each.value, "source_address_prefixes", null)
  source_address_prefix   = lookup(each.value, "source_address_prefixes", null) != null ? null : lookup(each.value, "source_address_prefix", "*")

  # 端口
  source_port_ranges = lookup(each.value, "source_port_ranges", null)
  source_port_range  = lookup(each.value, "source_port_ranges", null) != null ? null : lookup(each.value, "source_port_range", "*")

  # 目标地址
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefixes", null) != null ? null : lookup(each.value, "destination_address_prefix", "*")

  # 目标端口
  destination_port_ranges = lookup(each.value, "destination_port_ranges", null)
  destination_port_range  = lookup(each.value, "destination_port_ranges", null) != null ? null : lookup(each.value, "destination_port_range", "*")
}





# 创建主机池 1
resource "azurerm_virtual_desktop_host_pool" "avd_pool_1" {
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name

  name                = var.avd_hostpool_1.name
  start_vm_on_connect = var.avd_hostpool_1.start_vm_on_connect
  type                = var.avd_hostpool_1.type



  # 仅当 friendly_name 被定义时，才设置 friendly_name
  friendly_name = try(var.avd_hostpool_1.friendly_name, null)

  # 仅当 type 为 "Pooled" 时，才设置 maximum_sessions_allowed
  maximum_sessions_allowed = var.avd_hostpool_1.type == "Pooled" ? try(var.avd_hostpool_1.maximum_sessions_allowed, null) : null

  # 根据主机池类型动态设置 load_balancer_type
  load_balancer_type = var.avd_hostpool_1.type == "Personal" ? "Persistent" : var.avd_hostpool_1.load_balancer_type
}





# 创建工作区 1
resource "azurerm_virtual_desktop_workspace" "workspace_1" {
  name                = var.workspace_1.name
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name

  # 条件设置 friendly_name，只在存在时才设置
  friendly_name = try(var.workspace_1.friendly_name, null)
}



# 创建主机池1——应用程序组 1
resource "azurerm_virtual_desktop_application_group" "app_group_1" {
  name                = var.app_group_1.name
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name

  type         = var.app_group_1.type
  host_pool_id = azurerm_virtual_desktop_host_pool.avd_pool_1.id
}


# 注册APP组1到主机池1
resource "azurerm_virtual_desktop_workspace_application_group_association" "workspace_1_register_pool_1" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace_1.id
  application_group_id = azurerm_virtual_desktop_application_group.app_group_1.id
}



#创建 avdfile 备份的存储账户
resource "azurerm_storage_account" "avdfile_storage" {
  name                = var.avdfile_storage.name
  resource_group_name = azurerm_resource_group.avd_rg.name

  location                      = azurerm_resource_group.avd_rg.location
  account_tier                  = var.avdfile_storage.account_tier
  account_replication_type      = var.avdfile_storage.account_replication_type
  access_tier                   = var.avdfile_storage.access_tier
  public_network_access_enabled = var.avdfile_storage.public_network_access_enabled

}

# 查询 avdfileSubnet 子网的数据源
data "azurerm_subnet" "avdfileSubnet" {
  name                 = var.avd_vnet_subnets["AVDfileSubnet"].name
  virtual_network_name = azurerm_virtual_network.avd_vnet.name
  resource_group_name  = azurerm_resource_group.avd_rg.name
}


# 为 avdfile储存账户创建专用终结点，放在avdfile子网，连接类型为file
resource "azurerm_private_endpoint" "avdfile_pe" {
  name                = var.avdfile_pe.name
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  subnet_id           = data.azurerm_subnet.avdfileSubnet.id

  private_service_connection {
    name                           = var.avdfile_pe.private_service_connection.name
    private_connection_resource_id = azurerm_storage_account.avdfile_storage.id
    subresource_names              = var.avdfile_pe.private_service_connection.subresource_names    #["blob"]
    is_manual_connection           = var.avdfile_pe.private_service_connection.is_manual_connection # false
  }

}

################################################
# Filebu Module
################################################

#创建 filebu 模块
resource "azurerm_resource_group" "filebu_rg" {
  name     = var.filebu_rg.name
  location = var.project_main_location
}



#创建filebu 虚拟网络
resource "azurerm_virtual_network" "filebu_vnet" {
  name                = var.filebu_vnet.name
  location            = azurerm_resource_group.filebu_rg.location
  resource_group_name = azurerm_resource_group.filebu_rg.name
  address_space       = var.filebu_vnet.address_space
  dns_servers         = azurerm_network_interface.nic_dc.private_ip_addresses


  subnet {
    name             = var.filebu_vnet_subnets["FilebuSubnet"].name
    address_prefixes = var.filebu_vnet_subnets["FilebuSubnet"].address_prefixes
    security_group   = azurerm_network_security_group.filebu_subnet_sg.id
  }

}


#创建 filebu子网的安全组
resource "azurerm_network_security_group" "filebu_subnet_sg" {
  name                = var.filebu_subnet_sg.name
  location            = azurerm_resource_group.filebu_rg.location
  resource_group_name = azurerm_resource_group.filebu_rg.name

}

#创建 filebu子网的安全组安全规则
resource "azurerm_network_security_rule" "filebu_subnet_sg_rules" {
  for_each = var.filebu_subnet_sg_rules

  resource_group_name         = azurerm_resource_group.filebu_rg.name
  network_security_group_name = azurerm_network_security_group.filebu_subnet_sg.name

  name      = each.key
  priority  = each.value.priority
  direction = each.value.direction
  access    = each.value.access
  protocol  = each.value.protocol

  # 源地址
  source_address_prefixes = lookup(each.value, "source_address_prefixes", null)
  source_address_prefix   = lookup(each.value, "source_address_prefixes", null) != null ? null : lookup(each.value, "source_address_prefix", "*")

  # 端口
  source_port_ranges = lookup(each.value, "source_port_ranges", null)
  source_port_range  = lookup(each.value, "source_port_ranges", null) != null ? null : lookup(each.value, "source_port_range", "*")

  # 目标地址
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefixes", null) != null ? null : lookup(each.value, "destination_address_prefix", "*")

  # 目标端口
  destination_port_ranges = lookup(each.value, "destination_port_ranges", null)
  destination_port_range  = lookup(each.value, "destination_port_ranges", null) != null ? null : lookup(each.value, "destination_port_range", "*")
}





#创建 filebu 备份的存储账户
resource "azurerm_storage_account" "filebu_storage" {
  name                = var.filebu_storage.name
  resource_group_name = azurerm_resource_group.filebu_rg.name

  location                      = azurerm_resource_group.filebu_rg.location
  account_tier                  = var.filebu_storage.account_tier
  account_replication_type      = var.filebu_storage.account_replication_type
  access_tier                   = var.filebu_storage.access_tier
  public_network_access_enabled = var.filebu_storage.public_network_access_enabled

}

# 查询 filebuSubnet 子网的ID
data "azurerm_subnet" "filebuSubnet" {
  name                 = var.filebu_vnet_subnets["FilebuSubnet"].name
  virtual_network_name = azurerm_virtual_network.filebu_vnet.name
  resource_group_name  = azurerm_resource_group.filebu_rg.name
}
# 为 filebu储存账户创建专用终结点，放在filebu子网，连接类型为blob
resource "azurerm_private_endpoint" "filebu_pe" {
  name                = var.filebu_pe.name
  location            = azurerm_resource_group.filebu_rg.location
  resource_group_name = azurerm_resource_group.filebu_rg.name
  subnet_id           = data.azurerm_subnet.filebuSubnet.id

  private_service_connection {
    name                           = var.filebu_pe.private_service_connection.name
    private_connection_resource_id = azurerm_storage_account.filebu_storage.id
    subresource_names              = var.filebu_pe.private_service_connection.subresource_names    #["blob"]
    is_manual_connection           = var.filebu_pe.private_service_connection.is_manual_connection # false
  }

}



#创建文件同步服务
resource "azurerm_storage_sync" "file-sync" {
  name                = var.file_sync_name
  resource_group_name = azurerm_resource_group.filebu_rg.name
  location            = azurerm_resource_group.filebu_rg.location
}




################################################
# Veeambu Module
################################################


#创建 Veeambu的资源组
resource "azurerm_resource_group" "veeambu_rg" {
  name     = var.veeambu_rg.name
  location = var.project_main_location
}



#创建 Veeambu 子网
resource "azurerm_virtual_network" "veeambu_vnet" {
  name                = var.veeambu_vnet.name
  location            = azurerm_resource_group.veeambu_rg.location
  resource_group_name = azurerm_resource_group.veeambu_rg.name
  address_space       = var.veeambu_vnet.address_space
  dns_servers         = azurerm_network_interface.nic_dc.private_ip_addresses


  subnet {
    name             = var.veeambu_vnet_subnets["VeeambuSubnet"].name
    address_prefixes = var.veeambu_vnet_subnets["VeeambuSubnet"].address_prefixes
    security_group   = azurerm_network_security_group.veeambu_subnet_sg.id
  }


}


#创建 Veeambu子网的安全组
resource "azurerm_network_security_group" "veeambu_subnet_sg" {
  name                = var.veeambu_subnet_sg.name
  location            = azurerm_resource_group.veeambu_rg.location
  resource_group_name = azurerm_resource_group.veeambu_rg.name

}

#创建 Veeambu 子网的安全组规则
resource "azurerm_network_security_rule" "veeambu_subnet_sg_rules" {
  for_each = var.veeambu_subnet_sg_rules

  resource_group_name         = azurerm_resource_group.veeambu_rg.name
  network_security_group_name = azurerm_network_security_group.veeambu_subnet_sg.name

  name      = each.key
  priority  = each.value.priority
  direction = each.value.direction
  access    = each.value.access
  protocol  = each.value.protocol

  # 源地址
  source_address_prefixes = lookup(each.value, "source_address_prefixes", null)
  source_address_prefix   = lookup(each.value, "source_address_prefixes", null) != null ? null : lookup(each.value, "source_address_prefix", "*")

  # 端口
  source_port_ranges = lookup(each.value, "source_port_ranges", null)
  source_port_range  = lookup(each.value, "source_port_ranges", null) != null ? null : lookup(each.value, "source_port_range", "*")

  # 目标地址
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefixes", null) != null ? null : lookup(each.value, "destination_address_prefix", "*")

  # 目标端口
  destination_port_ranges = lookup(each.value, "destination_port_ranges", null)
  destination_port_range  = lookup(each.value, "destination_port_ranges", null) != null ? null : lookup(each.value, "destination_port_range", "*")
}





#创建 Veeambu 备份的存储账户
resource "azurerm_storage_account" "veeambu_storage" {
  name                = var.veeambu_storage.name
  resource_group_name = azurerm_resource_group.veeambu_rg.name

  location                      = azurerm_resource_group.veeambu_rg.location
  account_tier                  = var.veeambu_storage.account_tier
  account_replication_type      = var.veeambu_storage.account_replication_type
  access_tier                   = var.veeambu_storage.access_tier
  public_network_access_enabled = var.veeambu_storage.public_network_access_enabled

}


# 查询 VeeambuSubnet 子网的ID
data "azurerm_subnet" "VeeambuSubnet" {
  name                 = var.veeambu_vnet_subnets["VeeambuSubnet"].name
  virtual_network_name = azurerm_virtual_network.veeambu_vnet.name
  resource_group_name  = azurerm_resource_group.veeambu_rg.name
}
# 为 veeambu储存账户创建专用终结点，放在Veeambu子网，连接类型为blob
resource "azurerm_private_endpoint" "veeambu_pe" {
  name                = var.veeambu_pe.name
  location            = azurerm_resource_group.veeambu_rg.location
  resource_group_name = azurerm_resource_group.veeambu_rg.name
  subnet_id           = data.azurerm_subnet.VeeambuSubnet.id

  private_service_connection {
    name                           = var.veeambu_pe.private_service_connection.name
    private_connection_resource_id = azurerm_storage_account.veeambu_storage.id
    subresource_names              = var.veeambu_pe.private_service_connection.subresource_names    #["blob"]
    is_manual_connection           = var.veeambu_pe.private_service_connection.is_manual_connection # false
  }

}












# ----------------------------------------------对等互联-------------------------------------------------



# HUB vnet —————————— avd vnet
resource "azurerm_virtual_network_peering" "hub_peer_avd" {
  depends_on                = [azurerm_virtual_network.hub_vnet, azurerm_virtual_network.avd_vnet]
  name                      = var.hub_peer_avd_name
  resource_group_name       = azurerm_resource_group.hub_rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.avd_vnet.id

  allow_virtual_network_access = true
  allow_gateway_transit        = true
}
#avd vnet —————————— HUB vnet
resource "azurerm_virtual_network_peering" "avd_peer_hub" {
  depends_on                = [azurerm_virtual_network.hub_vnet, azurerm_virtual_network.avd_vnet]
  name                      = var.avd_peer_hub_name
  resource_group_name       = azurerm_resource_group.avd_rg.name
  virtual_network_name      = azurerm_virtual_network.avd_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
}




resource "azurerm_virtual_network_peering" "hub_peer_filebu" {
  depends_on                = [azurerm_virtual_network.hub_vnet, azurerm_virtual_network.filebu_vnet]
  name                      = var.hub_peer_filebu_name
  resource_group_name       = azurerm_resource_group.hub_rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.filebu_vnet.id

  allow_virtual_network_access = true
  allow_gateway_transit        = true
}
resource "azurerm_virtual_network_peering" "filebu_peer_hub" {
  depends_on                = [azurerm_virtual_network.hub_vnet, azurerm_virtual_network.filebu_vnet]
  name                      = var.filebu_peer_hub_name
  resource_group_name       = azurerm_resource_group.filebu_rg.name
  virtual_network_name      = azurerm_virtual_network.filebu_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
}



resource "azurerm_virtual_network_peering" "hub_peer_veeambu" {
  depends_on                = [azurerm_virtual_network.hub_vnet, azurerm_virtual_network.veeambu_vnet]
  name                      = var.hub_peer_veeambu_name
  resource_group_name       = azurerm_resource_group.hub_rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.veeambu_vnet.id

  allow_virtual_network_access = true
  allow_gateway_transit        = true
}
resource "azurerm_virtual_network_peering" "veeambu_peer_hub" {
  depends_on                = [azurerm_virtual_network.hub_vnet, azurerm_virtual_network.veeambu_vnet]
  name                      = var.veeambu_peer_hub_name
  resource_group_name       = azurerm_resource_group.veeambu_rg.name
  virtual_network_name      = azurerm_virtual_network.veeambu_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
}




#avd vnet —————————— filebu vnet
resource "azurerm_virtual_network_peering" "avd_peer_filebu" {
  depends_on                = [azurerm_virtual_network.filebu_vnet, azurerm_virtual_network.avd_vnet]
  name                      = var.avd_peer_filebu_name
  resource_group_name       = azurerm_resource_group.avd_rg.name
  virtual_network_name      = azurerm_virtual_network.avd_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.filebu_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "filebu_peer_avd" {
  depends_on                = [azurerm_virtual_network.hub_vnet, azurerm_virtual_network.filebu_vnet]
  name                      = var.filebu_peer_avd_name
  resource_group_name       = azurerm_resource_group.filebu_rg.name
  virtual_network_name      = azurerm_virtual_network.filebu_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.avd_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

data "azurerm_firewall" "lookup_firewall" {
  name                = azurerm_firewall.firewall_hub.name
  resource_group_name = azurerm_firewall.firewall_hub.resource_group_name
}



module "route_table" {
  source = "./UDR"
  internet_route_firewall_udr = {
    name = var.route_table_1.name
    location = azurerm_firewall.firewall_hub.location
    resource_group_name = azurerm_firewall.firewall_hub.resource_group_name
  }
  firewall_ip_address = data.azurerm_firewall.lookup_firewall.ip_configuration[0].private_ip_address
}
