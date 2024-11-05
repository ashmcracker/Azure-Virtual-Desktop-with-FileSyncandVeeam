

resource "azurerm_firewall_policy" "firewall_policy" {
  name                = var.firewall_policy.name
  resource_group_name = var.firewall_policy.resource_group_name
  location            = var.firewall_policy.location

  # DNS 配置块，根据变量启用 DNS 代理
  dns {
    proxy_enabled = var.firewall_policy.proxy_enabled  # 使用变量控制是否启用 DNS 代理
    servers       = var.firewall_policy.dns_servers    # 使用自定义 DNS 服务器列表
  }
}



# 应用程序规则集合组
resource "azurerm_firewall_policy_rule_collection_group" "application_rules" {
  name               = "DefaultApplicationRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = 300

  application_rule_collection {
    name     = "allow_AVD"
    priority = 100
    action   = "Allow"

    # Rule: ServiceTraffic
    rule {
      name             = "ServiceTraffic"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["*.wvd.azure.cn"]
    }

    # Rule: ProxyTraffic
    rule {
      name             = "ProxyTraffic"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["*.prod.warm.ingest.monitor.core.chinacloudapi.cn"]
    }

    # Rule: AuthenticationToAzureOnlineServices
    rule {
      name             = "AuthenticationToAzureOnlineServices"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["*.chinacloudapi.cn"]
    }

    # Rule: Telemetry
    rule {
      name             = "Telemetry"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["*.events.data.microsoft.com"]
    }

    # Rule: OSConnectivityCheck
    rule {
      name             = "OSConnectivityCheck"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["www.msftconnecttest.com"]
    }

    # Rule: WindowsUpdate
    rule {
      name             = "WindowsUpdate"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["*.prod.do.dsp.mp.microsoft.com"]
    }

    # Rule: OneDriveUpdate
    rule {
      name             = "OneDriveUpdate"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["*.sfx.ms"]
    }

    # Rule: CertificateRevocationCheck
    rule {
      name             = "CertificateRevocationCheck"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["*.digicert.com"]
    }

    # Rule: AzureDNSResolution
    rule {
      name             = "AzureDNSResolution"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["*.azure-dns.com"]
    }

    # Rule: AzureDNSResolution1
    rule {
      name             = "AzureDNSResolution1"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["*.azure-dns.net"]
    }

    # Rule: Certificate1
    rule {
      name             = "Certificate1"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["crl.digincert.cn"]
    }

    # Rule: Certificate2
    rule {
      name             = "Certificate2"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["microsoft.com"]
    }

    # Rule: MSOnline_Auth
    rule {
      name             = "MSOnline_Auth"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["login.partner.microsoftonline.cn"]
    }
  }

  # Additional Application Rule Collections, e.g., allow_o365, can be defined here as needed...
}

# 网络规则集合组
resource "azurerm_firewall_policy_rule_collection_group" "network_rules" {
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = 200

  network_rule_collection {
    name     = "allow_AVD"
    priority = 100
    action   = "Allow"

    # Rule: WindowsActivation
    rule {
      name                  = "WindowsActivation"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_fqdns     = ["kms.core.chinacloudapi.cn"]
      destination_ports     = ["1688"]
    }

    # Rule: AzureIMDSEndpoint
    rule {
      name                  = "AzureIMDSEndpoint"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["169.254.169.254"]
      destination_ports     = ["80"]
    }

    # Rule: SessionHostHealthMonitoring
    rule {
      name                  = "SessionHostHealthMonitoring"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["168.63.129.16"]
      destination_ports     = ["80"]
    }

    # Rule: AzureCloud
    rule {
      name                  = "AzureCloud"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud", "AzureCloud.chinanorth2"]
      destination_ports     = ["443"]
    }

    # Rule: ADFS
    rule {
      name                  = "ADFS"
      protocols             = ["Any"]
      source_addresses      = ["*"]
      destination_addresses = ["61.238.148.157"]
      destination_ports     = ["*"]
    }

    # Rule: ADFS01
    rule {
      name                  = "ADFS01"
      protocols             = ["Any"]
      source_addresses      = ["*"]
      destination_fqdns     = [
        "adfs.johnsonelectric.com",
        "autodiscover.johnsonelectric.com",
        "autod.ms-acdc-autod.office.com"
      ]
      destination_ports     = ["*"]
    }
  }

  # Additional Network Rule Collections, e.g., allow_outlook, can be defined here as needed...
  
  # 应用程序规则集合 - allow_o365
  application_rule_collection {
    name     = "allow_o365"
    priority = 102
    action   = "Allow"

    # Rule: allow_outlook
    rule {
      name             = "allow_outlook"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      destination_fqdns = [
        "*.virtualearth.net",
        "c.bing.net",
        "ocos-office365-s2s.msedge.net",
        "tse1.mm.bing.net",
        "www.bing.com",
        "login.windows-ppe.net",
        "account.live.com",
        "login.live.com",
        "www.acompli.com",
        "*.assets-yammer.com",
        "*.yammer.com",
        "*.yammerusercontent.com",
        "www.outlook.com",
        "*.azure-apim.net",
        "*.flow.microsoft.com",
        "*.powerapps.com",
        "*.powerautomate.com",
        "cdn.odc.officeapps.live.com",
        "cdn.uci.officeapps.live.com",
        "*.cloud.microsoft",
        "*.static.microsoft",
        "*.usercontent.microsoft",
        "admin.microsoft.com",
        "*.hip.live.com",
        "*.microsoftonline-p.com",
        "*.microsoftonline.com",
        "*.msauth.net",
        "*.msauthimages.net",
        "*.msecnd.net",
        "*.msftauth.net",
        "*.msftauthimages.net",
        "*.phonefactor.net",
        "enterpriseregistration.windows.net",
        "policykeyservice.dc.ad.msft.net",
        "*.protection.office.com",
        "*.security.microsoft.com",
        "compliance.microsoft.com",
        "defender.microsoft.com",
        "protection.office.com",
        "purview.microsoft.com",
        "security.microsoft.com",
        "*.portal.cloudappsecurity.com",
        "firstpartyapps.oaspapps.com",
        "prod.firstpartyapps.oaspapps.com.akadns.net",
        "telemetryservice.firstpartyapps.oaspapps.com",
        "wus-firstpartyapps.oaspapps.com",
        "*.aria.microsoft.com",
        "*.events.data.microsoft.com",
        "*.o365weve.com",
        "amp.azure.net",
        "appsforoffice.microsoft.com",
        "assets.onestore.ms",
        "auth.gfx.ms",
        "c1.microsoft.com",
        "dgps.support.microsoft.com",
        "docs.microsoft.com",
        "msdn.microsoft.com",
        "platform.linkedin.com",
        "prod.msocdn.com",
        "shellprod.msocdn.com",
        "support.microsoft.com",
        "technet.microsoft.com",
        "*.office365.com",
        "*.aadrm.com",
        "*.azurerms.com",
        "*.informationprotection.azure.com",
        "ecn.dev.virtualearth.net",
        "informationprotection.hosting.portal.azure.net",
        "*.sharepointonline.com",
        "dc.services.visualstudio.com",
        "mem.gfx.ms",
        "staffhub.ms",
        "staffhubweb.azureedge.net",
        "*.microsoft.com",
        "*.msocdn.com",
        "*.onmicrosoft.com",
        "o15.officeredir.microsoft.com",
        "officepreviewredir.microsoft.com",
        "officeredir.microsoft.com",
        "r.office.microsoft.com",
        "activation.sls.microsoft.com",
        "crl.microsoft.com",
        "office15client.microsoft.com",
        "officeclient.microsoft.com",
        "go.microsoft.com",
        "ajax.aspnetcdn.com",
        "officecdn.microsoft.com",
        "officecdn.microsoft.com.edgesuite.net",
        "otelrules.azureedge.net",
        "*.auth.microsoft.com",
        "*.msftidentity.com",
        "*.msidentity.com",
        "account.activedirectory.windowsazure.com",
        "accounts.accesscontrol.windows.net",
        "adminwebservice.microsoftonline.com",
        "api.passwordreset.microsoftonline.com",
        "autologon.microsoftazuread-sso.com",
        "becws.microsoftonline.com",
        "ccs.login.microsoftonline.com",
        "clientconfig.microsoftonline-p.net",
        "companymanager.microsoftonline.com",
        "device.login.microsoftonline.com",
        "graph.microsoft.com",
        "graph.windows.net",
        "login-us.microsoftonline.com",
        "login.microsoft.com",
        "login.microsoftonline-p.com",
        "login.microsoftonline.com",
        "login.windows.net",
        "logincert.microsoftonline.com",
        "loginex.microsoftonline.com",
        "nexus.microsoftonline-p.com",
        "passwordreset.microsoftonline.com",
        "provisioningapi.microsoftonline.com",
        "*.office.net",
        "*.onenote.com",
        "*cdn.onenote.net",
        "apis.live.net",
        "officeapps.live.com",
        "www.onedrive.com",
        "*.officeapps.live.com",
        "*.online.office.com",
        "office.live.com",
        "outlook.live.com",
        "outlook.cloud.microsoft",
        "outlook.office.com",
        "outlook.office365.com",
        "*.outlook.com",
        "*.protection.outlook.com"
      ]
    }

    # Rule: allow_powerbi
    rule {
      name             = "allow_powerbi"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = [
        "api.powerbi.com",
        "*.analysis.windows.net",
        "*.pbidedicated.windows.net",
        "content.powerapps.com",
        "datamart.fabric.microsoft.com",
        "datamart.pbidedicated.windows.net",
        "*.powerbi.com",
        "gatewayadminportal.azure.com",
        "dc.services.visualstudio.com",
        "appsource.microsoft.com",
        "*.s-microsoft.com",
        "*.osi.office.net",
        "*.msecnd.net",
        "store.office.com",
        "store-images.s-microsoft.com",
        "visuals.azureedge.net"
      ]
    }

    # Rule: allow_sharepoint
    rule {
      name             = "allow_sharepoint"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      destination_fqdns = [
        "*.sharepoint.com",
        "*.sharepointonline.com",
        "spoprod-a.akamaihd.net"
      ]
    }

    # Rule: allow_onedrive
    rule {
      name             = "allow_onedrive"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      destination_fqdns = [
        "onedrive.com",
        "*.onedrive.com",
        "onedrive.live.com",
        "login.live.com",
        "g.live.com",
        "spoprod-a.akamaihd.net",
        "*.mesh.com",
        "p.sfx.ms",
        "oneclient.sfx.ms",
        "*.microsoft.com",
        "fabric.io",
        "*.crashlytics.com",
        "vortex.data.microsoft.com",
        "posarprodcssservice.accesscontrol.windows.net",
        "redemptionservices.accesscontrol.windows.net",
        "token.cp.microsoft.com",
        "tokensit.cp.microsoft-tst.com",
        "*.office.com",
        "*.officeapps.live.com",
        "*.aria.microsoft.com",
        "*.mobileengagement.windows.net",
        "*.branch.io",
        "*.adjust.com",
        "*.servicebus.windows.net",
        "vas.samsungapps.com",
        "odc.officeapps.live.com",
        "login.windows.net",
        "login.microsoftonline.com",
        "*.files.1drv.com",
        "*.onedrive.live.com",
        "storage.live.com",
        "*.storage.live.com",
        "*.groups.office.live.com",
        "*.groups.photos.live.com",
        "*.groups.skydrive.live.com",
        "favorites.live.com",
        "oauth.live.com",
        "photos.live.com",
        "skydrive.live.com",
        "api.live.net",
        "apis.live.net",
        "docs.live.net",
        "*.docs.live.net",
        "policies.live.net",
        "*.policies.live.net",
        "settings.live.net",
        "*.settings.live.net",
        "skyapi.live.net",
        "snapi.live.net",
        "*.livefilestore.com",
        "storage.msn.com",
        "*.storage.msn.com",
        "client.wns.windows.com"
      ]
    }

    # Rule: allow_sharepointExtraPort
    rule {
      name             = "allow_sharepointExtraPort"
      source_addresses = ["*"]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = [
        "*.sharepoint.com",
        "ssw.live.com",
        "storage.live.com",
        "*.search.production.apac.trafficmanager.net",
        "*.search.production.emea.trafficmanager.net",
        "*.search.production.us.trafficmanager.net",
        "*.wns.windows.com",
        "admin.onedrive.com",
        "officeclient.microsoft.com",
        "g.live.com",
        "oneclient.sfx.ms",
        "*.sharepointonline.com",
        "spoprod-a.akamaihd.net",
        "*.svc.ms"
      ]
    }

    # Rule: allow_power_auto
    rule {
      name             = "allow_power_auto"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      destination_fqdns = [
        "login.microsoft.com",
        "login.windows.net",
        "login.microsoftonline.com",
        "login.live.com",
        "secure.aadcdn.microsoftonline-p.com",
        "graph.microsoft.com",
        "*.azure-apim.net",
        "*.azure-apihub.net",
        "*.blob.core.windows.net",
        "*.flow.microsoft.com",
        "*.logic.azure.com",
        "*.powerautomate.com",
        "*.powerapps.com",
        "*.azureedge.net",
        "*.microsoftcloud.com",
        "webshell.suite.office.com",
        "*.dynamics.com",
        "go.microsoft.com",
        "download.microsoft.com",
        "login.partner.microsoftonline.cn",
        "s2s.config.skype.com",
        "use.config.skype.com",
        "s2s.config.ecs.infra.gov.teams.microsoft.us",
        "*.api.powerplatform.com",
        "*.api.powerplatformusercontent.com",
        "*.events.data.microsoft.com",
        "collector.azure.cn",
        "officeapps.live.com",
        "ocsp.digicert.com",
        "ocsp.msocsp.com",
        "mscrl.microsoft.com",
        "crl3.digicert.com",
        "crl4.digicert.com",
        "*.servicebus.windows.net",
        "*.gateway.prod.island.powerapps.com",
        "emea.events.data.microsoft.com",
        "fpc.msedge.net",
        "ctldl.windowsupdate.com"
      ]
    }
  }
}

