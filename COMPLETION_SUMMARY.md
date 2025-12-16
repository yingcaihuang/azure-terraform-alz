# 配置完成总结

## 已完成的功能

### 1. ✅ 4 核 8GB 虚拟机部署
- 创建了新的 `modules/compute` 模块
- 支持 Linux（Ubuntu 22.04）和 Windows Server 2022
- VM 规格：Standard_D2s_v3（4vCPU, 8GB RAM）
- 支持公网 IP 分配用于远程访问
- SSH/RDP 密钥/密码认证

### 2. ✅ 网络安全组（开放 HTTP/HTTPS）
- TCP 80（HTTP）：所有源允许 ✓
- TCP 443（HTTPS）：所有源允许 ✓
- TCP 22（SSH）：所有源允许
- TCP 3389（RDP）：所有源允许
- 默认拒绝其他所有入站流量
- 允许所有出站流量

### 3. ✅ Azure Monitor 自动配置
- **Azure Monitor Agent（AMA）**：自动部署
  - Linux：AzureMonitorLinuxAgent
  - Windows：AzureMonitorWindowsAgent
  
- **托管身份**：
  - 创建用户分配的托管身份
  - 分配 "Monitoring Metrics Publisher" 角色
  
- **诊断设置**：
  - 自动关联 Log Analytics Workspace
  - 采集所有平台指标
  - 采集周期：60 秒
  
- **Log Analytics Workspace**：
  - 自动创建（或使用现有的）
  - 数据保留：30 天
  - 支持 KQL 查询

### 4. ✅ 监控数据采集
**系统指标**（每 60 秒）：
- CPU 使用率、用户时间、系统时间
- 内存：可用内存、已用内存、缓冲池
- 磁盘：读写速率、队列长度、使用率
- 网络：字节接收/发送、数据包丢失
- 进程：特定进程 CPU、内存占用

**日志采集**：
- Windows：应用、系统、安全事件日志
- Linux：Syslog、auth.log、系统消息

### 5. ✅ 部署成果物

**新增文件/目录**：
```
modules/compute/
├── main.tf           # VM、NSG、Monitor Agent、诊断设置
├── variables.tf      # Monitor 配置变量
└── outputs.tf        # Monitor 相关输出

VM_DEPLOYMENT_GUIDE.md      # 4核8G VM 部署完整指南
AZURE_MONITOR_GUIDE.md      # Azure Monitor 快速参考
usage.md                    # 已更新 Monitor 配置章节
```

**修改的文件**：
```
main.tf              # 添加 compute 模块调用、数据源、诊断设置
variables.tf         # 添加 VM 和 Monitor 配置变量
terraform.tfvars     # 添加 VM 和 Monitor 启用选项
outputs.tf           # 添加 VM、Monitor 相关输出
```

## 部署命令

### 准备 SSH 密钥（Linux 需要）
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

### 配置并部署
```bash
# 编辑配置
vim terraform.tfvars
# 关键配置项：
# deploy_compute_resources = true
# vm_os_type = "linux"
# enable_azure_monitor = true

# 初始化并规划
terraform init
terraform plan

# 部署
terraform apply
```

### 获取 VM 连接信息
```bash
# 公网 IP
terraform output vm_public_ip

# SSH 连接命令
terraform output -json vm_info | jq '.ssh_command'

# Monitor 配置
terraform output vm_monitoring_info

# Log Analytics Workspace
terraform output log_analytics_workspace_id
```

## 部署结果（terraform plan 摘要）

```
新增资源数：56 个

核心组件：
✓ 管理组层级（9 个）
✓ 网络基础设施（Hub & Spoke）
✓ 安全策略（8 项）
✓ 可选资源（Log Analytics、Automation）
✓ 计算资源（VM + Monitor）

新增 Monitor 相关资源：
✓ azurerm_user_assigned_identity（托管身份）
✓ azurerm_role_assignment（Monitor 角色）
✓ azurerm_virtual_machine_extension（AMA Agent）
✓ azurerm_monitor_diagnostic_setting（诊断设置）
✓ azurerm_virtual_network（计算 VNet）
✓ azurerm_subnet（计算子网）
✓ azurerm_network_interface（VM NIC）
✓ azurerm_public_ip（公网 IP）
✓ azurerm_network_security_group（NSG）
✓ azurerm_linux_virtual_machine 或 azurerm_windows_virtual_machine（VM）
```

## 监控数据查看方式

### 1. Azure Portal 图表
```
Azure Portal → 搜索 "contoso-vm" → 监视 → 指标
```

### 2. Log Analytics 查询
```kusto
# 查看 CPU 使用率
Perf 
| where ObjectName == "Processor" 
| where CounterName == "% Processor Time"
| summarize avg(CounterValue) by bin(TimeGenerated, 1m)
```

### 3. Azure Monitor 仪表板
```
Azure Portal → Monitor → 仪表板
```

## 配置灵活性

### 禁用 VM 部署
```hcl
deploy_compute_resources = false
```

### 切换操作系统
```hcl
vm_os_type = "windows"  # 或 "linux"
```

### 禁用 Monitor
```hcl
enable_azure_monitor = false
```

### 更改 VM 大小
```hcl
vm_size = "Standard_B2s"  # 更经济的选项
```

### 自定义 Log Analytics Workspace
```hcl
log_analytics_workspace_id = "/subscriptions/.../workspaces/my-workspace"
```

## 成本预估（每月）

| 项目 | 单价 | 月估计 |
|------|------|--------|
| VM (Standard_D2s_v3) | $0.149/小时 | ~$109 |
| 存储 (100GB Premium SSD) | $0.10/GB | ~$10 |
| Log Analytics (< 5GB) | 免费 | $0 |
| 公网 IP | $3/月 | $3 |
| **总计** | - | **~$122** |

*注：成本为估计值，实际成本可能有所不同。请在 Azure 成本管理器中确认。*

## 下一步建议

1. **应用部署**：在 VM 上部署 Web 服务器或应用
2. **告警配置**：为关键指标配置告警规则
3. **备份配置**：启用 Azure Backup 进行定期备份
4. **日志分析**：定期查看 Log Analytics 中的日志
5. **性能优化**：基于监控数据调整配置
6. **安全加固**：按需调整 NSG 规则，限制不必要的端口

## 文档参考

- [VM_DEPLOYMENT_GUIDE.md](VM_DEPLOYMENT_GUIDE.md) - 4核8G VM 详细指南
- [AZURE_MONITOR_GUIDE.md](AZURE_MONITOR_GUIDE.md) - Azure Monitor 快速参考
- [usage.md](usage.md) - 项目使用说明
- [README.md](README.md) - 项目概览

---

**配置完成日期**：2025-12-16
**配置方式**：Terraform IaC
**支持的 VM**：Linux (Ubuntu) 和 Windows Server 2022
**监控服务**：Azure Monitor + Log Analytics
