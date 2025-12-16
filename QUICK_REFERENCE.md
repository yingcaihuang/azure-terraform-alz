# 快速参考卡

## 🚀 3 分钟快速部署

### 第 1 步：准备 SSH 密钥（Linux 需要）
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

### 第 2 步：编辑 terraform.tfvars
```bash
# 关键配置
deploy_compute_resources = true        # 启用 VM
enable_azure_monitor = true            # 启用 Monitor
deploy_log_analytics_workspace = true  # 启用日志工作区
vm_os_type = "linux"                   # 或 "windows"
```

### 第 3 步：部署
```bash
terraform plan
terraform apply
```

## 📊 部署后立即可用

### 查看 VM 信息
```bash
terraform output vm_info
terraform output vm_public_ip
```

### SSH 连接（Linux）
```bash
PUBLIC_IP=$(terraform output -raw vm_public_ip)
ssh -i ~/.ssh/id_rsa azureuser@$PUBLIC_IP
```

### 查看 Monitor 状态
```bash
terraform output vm_monitoring_info
terraform output log_analytics_workspace_id
```

## 🔗 Azure Portal 快速导航

| 功能 | 路径 |
|------|------|
| **VM 监控** | VM 详情 → 监视 → 指标 |
| **性能图表** | Monitor → 仪表板 |
| **日志查询** | Log Analytics → 日志 |
| **告警设置** | Monitor → 告警 → 新建 |
| **成本分析** | 成本管理 → 成本分析 |

## 💡 常用 KQL 查询

### CPU 使用率（最近 1 小时）
```kusto
Perf 
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where TimeGenerated > ago(1h)
| summarize AvgCPU=avg(CounterValue) by bin(TimeGenerated, 5m)
```

### 内存使用趋势（最近 24 小时）
```kusto
Perf 
| where ObjectName == "Memory" 
| where TimeGenerated > ago(24h)
| summarize AvgMemory=avg(CounterValue) by bin(TimeGenerated, 1h)
```

### 错误事件（最近 24 小时）
```kusto
Event 
| where EventLevelName == "Error"
| where TimeGenerated > ago(24h)
```

## 🎯 配置选项

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `deploy_compute_resources` | `false` | 启用/禁用 VM |
| `vm_os_type` | `linux` | Linux 或 Windows |
| `vm_size` | `Standard_D2s_v3` | 4vCPU, 8GB |
| `assign_public_ip` | `true` | 分配公网 IP |
| `enable_azure_monitor` | `true` | 启用 Monitor |
| `admin_username` | `azureuser` | 管理员用户名 |

## 🔐 安全组规则

| 端口 | 协议 | 源 | 状态 |
|------|------|-----|------|
| 80 | TCP | * | ✅ 允许 |
| 443 | TCP | * | ✅ 允许 |
| 22 | TCP | * | ✅ 允许 |
| 3389 | TCP | * | ✅ 允许 |
| 其他 | * | * | ❌ 拒绝 |

## 📈 Monitor 采集内容

**系统指标**（每 60 秒）
- CPU 使用率、内存、磁盘、网络
- 进程监控
- 连接状态

**日志数据**
- 应用日志
- 系统事件
- 安全日志

## 💰 成本参考（每月）

```
VM (Standard_D2s_v3)    ≈ $109
存储 (100GB)            ≈ $10
Log Analytics (免费)     = $0
公网 IP                 = $3
─────────────────────
总计                    ≈ $122
```

## 🆘 故障排除

| 问题 | 解决方案 |
|------|---------|
| Agent 失败 | 检查托管身份权限 + 网络连接 |
| 无监控数据 | 等待 2-5 分钟启动 + 检查诊断设置 |
| 查询无结果 | 扩大时间范围 + 检查计算机名称 |
| SSH 超时 | 验证 NSG 规则 + 公网 IP 分配 |

## 📚 文档快速链接

- **完成总结**：`COMPLETION_SUMMARY.md`
- **VM 指南**：`VM_DEPLOYMENT_GUIDE.md`
- **Monitor 参考**：`AZURE_MONITOR_GUIDE.md`
- **项目说明**：`usage.md`

## ⚡ 一行命令

```bash
# 部署完整栈
terraform apply -auto-approve

# 查看所有输出
terraform output

# 获取 SSH 命令
terraform output -json vm_info | jq '.ssh_command' -r

# 部署后查看脚本
./show-vm-info.sh

# 销毁所有资源
terraform destroy -auto-approve
```

## 🔄 常见操作

### 禁用 Monitor（保持 VM）
```hcl
enable_azure_monitor = false
```

### 禁用 VM（保持 ALZ）
```hcl
deploy_compute_resources = false
```

### 更改 VM 为 Windows
```hcl
vm_os_type = "windows"
admin_password = "YourSecurePassword123!"
```

### 关闭公网 IP（仅内部访问）
```hcl
assign_public_ip = false
```

---

**最后更新**：2025-12-16  
**支持的 OS**：Ubuntu 22.04, Windows Server 2022  
**Monitor 服务**：Azure Monitor + Log Analytics  
**基础设施**：Terraform 1.5+
