## 架构图
![架构图](./Overall%20architecture.jpg)




## Azure 提供者：使用 Azure CLI 进行身份验证

参考文档 ：https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli

Terraform 支持多种不同的方式来进行 Azure 身份验证：

在非交互式运行 Terraform（例如在 CI 服务器上）时，建议使用服务主体或托管服务身份。而在本地运行 Terraform 时，建议使用 Azure CLI 进行身份验证。

### 登录 Azure CLI

**注意**：
如果您使用的是中国或政府版 Azure 云服务，您需要先将 Azure CLI 配置为适配该云环境。可以使用以下命令进行配置：

```bash
az cloud set --name AzureChinaCloud|AzureUSGovernment
```

首先，使用用户账户、服务主体或托管身份登录 Azure CLI。

**用户账户**：

```bash
az login
```

登录成功后，可以列出与账户关联的订阅：

```bash
az account list
```

输出如下所示，其中 `id` 字段为 `subscription_id`：

```json
[
  {
    "cloudName": "AzureCloud",
    "id": "00000000-0000-0000-0000-000000000000",
    "isDefault": true,
    "name": "PAYG Subscription",
    "state": "Enabled",
    "tenantId": "00000000-0000-0000-0000-000000000000",
    "user": {
      "name": "user@example.com",
      "type": "user"
    }
  }
]
```

如果您有多个订阅，可以使用以下命令指定要使用的订阅：

```bash
az account set --subscription="SUBSCRIPTION_ID"
```
