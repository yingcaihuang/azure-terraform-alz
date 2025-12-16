# 使用说明：Azure Landing Zone Terraform 实施指南

本项目提供一套遵循 Microsoft Cloud Adoption Framework 的 Azure Landing Zone（ALZ）生产可用实现，使用 Terraform 快速、可控地部署：管理组层级、可选网络架构（Hub&Spoke / Virtual WAN / 无网络）、核心安全策略，以及集中化的监控与运维资源。

## 项目主要作用
- 管理组：建立完整的 ALZ 管理组树，支撑治理与分层策略。
- 网络架构（可选）：在「Hub&Spoke」或「Virtual WAN」之间选择，或仅部署治理不含网络。
- 安全策略（可选）：部署 8 项常用 Azure Policy（审计或强制模式）。
- 管理与监控（可选）：创建 Log Analytics 工作区、Automation 账户与数据收集规则。
- 可配置与分阶段：支持审计→网络→强制的渐进式上线策略，降低风险与成本。

## 目录结构
```
azure-terraform-alz/
├── main.tf                 # 顶层编排（调用各模块）
├── versions.tf             # Terraform/Provider 版本与后端配置
├── variables.tf            # 输入变量定义
├── locals.tf               # 本地计算值
├── outputs.tf              # 输出值
├── terraform.tfvars        # 环境配置（建议编辑）
├── backend.conf.example    # Terraform 后端模板（复制为 backend.conf）
├── validate-alz.sh         # 预检脚本（可选）
└── modules/
    ├── management_groups/  # 管理组层级
    ├── connectivity/       # 网络：Hub&Spoke 或 Virtual WAN
    ├── core_policies/      # 核心安全策略
    └── optional_resources/ # 监控与运维资源
```

## 部署前提
- Azure CLI 已登录并切到管理订阅：
```bash
az login
az account set --subscription "<management-subscription-id>"
```
- Terraform ≥ 1.5.0：
```bash
terraform version
```
- Terraform 远端状态后端（推荐使用 Azure Storage）
  - 需要一个存储账户与 Blob 容器，用于持久化 Terraform 状态。

## 配置后端（Terraform Backend）
推荐使用 `backend.conf` 文件（从示例复制后修改）：
```bash
cp backend.conf.example backend.conf
# 编辑 backend.conf，填入：
# resource_group_name     # 存储账户所在的资源组
# storage_account_name    # 存储账户名
# container_name          # 容器名（如 tfstate）
# key                     # 状态文件键（如 alz/terraform.tfstate）
# subscription_id         # 订阅 ID
# tenant_id               # 租户 ID
# use_azuread_auth=true   # 推荐使用 AAD 鉴权
```
也可通过 CLI 参数在 `terraform init` 时直接传入（不建议长期使用）：
```bash
terraform init \
  -backend-config="resource_group_name=rg-terraform-state-prod" \
  -backend-config="storage_account_name=stterraformstateprod001" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=alz/terraform.tfstate" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="subscription_id=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" \
  -backend-config="tenant_id=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```
后端鉴权方式：
- Azure AD（推荐）：`use_azuread_auth = true`
- 访问密钥：`access_key = "<storage account access key>"`
- SAS：`sas_token = "<sas-token>"`

## 编辑环境配置（terraform.tfvars）
在 `terraform.tfvars` 中设置关键参数示例：
```hcl
# 基础设置
root_management_group_name = "Contoso ALZ"
resource_prefix            = "contoso"
org_name                   = "contoso"
location                   = "westus3"

# 网络架构选择（三选一）
network_architecture           = "hub_spoke"  # 或 "vwan" / "none"
deploy_connectivity_resources  = true          # 是否部署网络模块

# 安全策略
deploy_core_policies    = true
policy_enforcement_mode = "DoNotEnforce"      # 先用审计模式

# 可选资源
deploy_log_analytics_workspace = true
deploy_automation_account      = true
```
如需为管理组分配订阅（可选）：
```hcl
connectivity_subscription_id = "00000000-0000-0000-0000-000000000000"
identity_subscription_id     = "11111111-1111-1111-1111-111111111111"
management_subscription_id   = "22222222-2222-2222-2222-222222222222"
```
Hub&Spoke 网络参数示例：
```hcl
hub_vnet_address_space = ["10.0.0.0/22"]

hub_subnets = {
  "snet-shared-services" = { address_prefixes = ["10.0.0.0/24"] }
  "snet-management"      = { address_prefixes = ["10.0.1.0/24"] }
  "AzureBastionSubnet"   = { address_prefixes = ["10.0.2.0/26"] }
  "AzureFirewallSubnet"  = { address_prefixes = ["10.0.3.0/26"] }
}
```
Virtual WAN 参数示例：
```hcl
virtual_hub_address_prefix   = "10.0.0.0/24"
deploy_express_route_gateway = false
deploy_vpn_gateway           = false
```

## 预检与部署
```bash
# 可选：运行预检脚本，验证 CLI、权限、变量配置等
./validate-alz.sh

# 初始化 Terraform（使用后端配置文件）
terraform init -backend-config=backend.conf

# 查看计划
terraform plan

# 执行部署
terraform apply
```

## 推荐部署策略
- 分阶段上线（推荐）：
```bash
# 阶段 0：后端配置
cp backend.conf.example backend.conf
# 编辑 backend.conf

# 阶段 0.5：预检
./validate-alz.sh

# 阶段 1：先部署管理组 + 审计策略
terraform init -backend-config=backend.conf
terraform apply -var="deploy_connectivity_resources=false" -var="policy_enforcement_mode=DoNotEnforce"

# 阶段 2：开启网络模块
terraform apply -var="deploy_connectivity_resources=true"

# 阶段 3：必要时切换策略为强制
terraform apply -var="policy_enforcement_mode=Default"
```
- 一次性部署（简单场景）：
```bash
./validate-alz.sh
terraform init -backend-config=backend.conf
terraform apply
```

## 部署产物（Outputs）
- 管理组 ID：用于后续订阅分配与策略作用域绑定。
- 网络资源 ID：Hub VNet 或 vWAN 资源，便于挂载 Spoke。
- 策略分配 ID：用于合规监控与报告。
- Log Analytics Workspace ID：方便工作负载接入中心化日志。

## 策略与合规
- 策略模式：
  - `DoNotEnforce`（审计）：仅报告违规，不阻断部署。
  - `Default`（强制）：阻断不合规资源。
- 常见策略范围：加密、HTTPS 强制、RDP/SSH 入站限制、KeyVault 清除保护、Activity Log 保留、区域白名单、标签要求等。
- 在 Azure Policy 面板查看合规性，确认后再切换至强制模式。

## 常见问题（FAQ）
- 如何为后端存储赋权？
  - 使用 AAD 鉴权需在存储账户上授予 `Storage Blob Data Contributor`，并在资源组上至少有 `Reader`。
- 能否从本地状态迁移到远端？
```bash
terraform init -backend-config=backend.conf -migrate-state
```
- 与官方 ALZ Accelerator 差异？
  - 本项目聚焦核心能力与简化部署：更少策略、无需复杂 CI/CD、易于理解与扩展。

## 后续建议
- 从审计模式开始，逐步启用强制。
- 在网络连通性验证后再接入工作负载。
- 建立成本标签与命名规范，方便成本分摊。

---

如需深入了解：Azure Landing Zones、Azure Policy、Hub-Spoke 与 Virtual WAN 官方文档。