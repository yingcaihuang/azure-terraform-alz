# VM 部署快速指南

## 快速开始（3步部署 4核8G VM + HTTP/HTTPS 开放）

### 第 1 步：准备 SSH 密钥（仅 Linux 需要）
```bash
# 如果已有 SSH 密钥对，跳过此步
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

### 第 2 步：编辑 terraform.tfvars，启用 VM
```hcl
# 计算资源配置
deploy_compute_resources = true
vm_size                  = "Standard_D2s_v3"  # 4vCPU, 8GB
vm_os_type              = "linux"             # 或 "windows"
assign_public_ip        = true                # 需要公网 IP 来远程访问

# Linux 专项配置
admin_username = "azureuser"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# Windows 专项配置（如果选 vm_os_type = "windows"）
# admin_password = "YourStrongPassword123!"
```

### 第 3 步：部署
```bash
terraform plan
terraform apply
```

## 部署后操作

### 获取连接信息
```bash
# 获取所有 VM 信息
terraform output vm_info

# 分别获取公网 IP 和私网 IP
terraform output vm_public_ip
terraform output vm_private_ip

# 获取安全组规则
terraform output security_group_info
```

### Linux VM 连接
```bash
# 获取公网 IP
PUBLIC_IP=$(terraform output -raw vm_public_ip)

# SSH 连接
ssh -i ~/.ssh/id_rsa azureuser@$PUBLIC_IP

# 验证 HTTP/HTTPS 端口
curl http://$PUBLIC_IP
curl https://$PUBLIC_IP
```

### Windows VM 连接
```bash
# 获取公网 IP
terraform output vm_public_ip

# 使用 RDP 客户端连接（Windows、macOS、Linux 都可用）
# 服务器地址：上述 IP 地址
# 用户名：azureuser
# 密码：terraform.tfvars 中设置的 admin_password
```

## 成本概算（westus3 区域）

| 规格 | 单价（/小时）| 月估计（730小时） |
|------|-------------|----------------|
| Standard_B2s | ~$0.062 | ~$45 |
| Standard_D2s_v3 | ~$0.149 | ~$109 |

（包含存储、网络等辅助成本另计，请在 Azure 成本管理器中查看实际成本）

## 安全组规则清单
- **TCP 80（HTTP）**：✓ 所有源
- **TCP 443（HTTPS）**：✓ 所有源
- **TCP 22（SSH）**：✓ 所有源（Linux 管理）
- **TCP 3389（RDP）**：✓ 所有源（Windows 管理）
- **其他入站**：✗ 拒绝
- **出站**：✓ 全允许

## 修改现有部署

### 关闭 VM 并销毁
```bash
# 删除 VM 及相关资源
terraform destroy -var="deploy_compute_resources=false"
```

### 修改 VM 规格
编辑 `terraform.tfvars`，修改 `vm_size`：
```bash
vm_size = "Standard_B2s"  # 改为成本更低的规格
terraform apply
```

### 添加其他安全组规则
直接编辑 [modules/compute/main.tf](modules/compute/main.tf)，在 `azurerm_network_security_group` 资源中新增 `security_rule` 块，然后 `terraform apply`。

## 故障排除

### SSH 连接超时
- 确认公网 IP 已分配：`terraform output vm_public_ip`
- 检查本地防火墙是否允许出站 SSH（22 端口）
- 确认 SSH 密钥路径正确：`ls -la ~/.ssh/id_rsa`
- 尝试显式指定密钥：`ssh -i ~/.ssh/id_rsa azureuser@<IP>`

### Windows RDP 连接失败
- 确认密码复杂度符合要求（含大小写、数字、特殊符号）
- 等待 VM 完全启动（部署后可能需要 2-3 分钟）
- 检查防火墙规则：`terraform output security_group_info`
- 用户名应为 `azureuser`（非 Administrator）

### HTTP/HTTPS 连接拒绝
- 确认安全组规则已应用：`terraform output security_group_info`
- 确认 VM 内部已运行 HTTP/HTTPS 服务（如 Apache、Nginx）
- 在 VM 上检查防火墙：`sudo ufw status`（Linux）

## Azure Monitor 监控配置

### 自动监控采集
部署时已默认启用 Azure Monitor Agent，自动采集以下数据：

#### 系统指标（每 60 秒采集）
- **CPU**：使用率 (%)、用户时间、系统时间
- **内存**：可用内存 (MB)、已用内存、缓冲页面池
- **磁盘**：读写速率 (MB/s)、队列长度、使用率 (%)
- **网络**：字节接收/发送速率、数据包丢失率
- **进程**：特定进程的 CPU、内存占用

#### 日志采集
- **Windows**：应用程序、系统、安全事件日志
- **Linux**：Syslog、auth.log、var/log/messages

### 查看监控数据（3 种方式）

#### 方式 1：Azure Portal 指标浏览器
```bash
Azure Portal → 搜索 VM "contoso-vm" → 监视 → 指标
# 选择指标：CPU、内存、磁盘读写等，查看图表
```

#### 方式 2：Log Analytics 工作区（推荐）
```bash
# 获取工作区 ID
terraform output log_analytics_workspace_id

# Azure Portal 导航
搜索 → Log Analytics 工作区 → 选择工作区 → 日志
```

编写 KQL 查询：
```kusto
# 查看过去 1 小时的 CPU 平均使用率
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "Processor"
| where CounterName == "% Processor Time"
| where InstanceName == "_Total"
| summarize AvgCPU = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| render timechart

# 查看内存使用趋势
Perf
| where TimeGenerated > ago(24h)
| where ObjectName == "Memory"
| where CounterName == "Available MBytes"
| summarize AvgMemory = avg(CounterValue) by Computer, bin(TimeGenerated, 1h)
| render areachart

# 查看最近 24 小时的错误事件
Event
| where TimeGenerated > ago(24h)
| where EventLevelName == "Error"
| summarize count() by Source, EventID
| render barchart
```

#### 方式 3：Azure Monitor Insights（可视化仪表板）
```bash
Azure Portal → Log Analytics Workspace → Insights
# 查看性能概览、连接、性能详情等预配置仪表板
```

### 配置告警（性能阈值）
```bash
# 创建 CPU 使用率告警
Azure Portal → VM "contoso-vm" → 监视 → 告警 → 新建告警规则

配置示例：
- 条件：CPU 使用率 (%) > 80
- 持续时间：5 分钟
- 操作：发送电子邮件或调用 Webhook
```

### 配置自定义指标采集（可选）
编辑 Data Collection Rule (DCR)，添加自定义日志路径：

**Linux 示例**：采集应用日志
```hcl
# 在 modules/compute/main.tf 中扩展
# 配置采集 /var/log/myapp/*.log
```

**Windows 示例**：采集事件跟踪日志
```hcl
# 配置采集特定事件 ID 的应用程序日志
```

### 监控成本评估
- **Log Analytics 免费层**：前 5 GB/月免费，超出按 $2.50/GB 计费
- **Azure Monitor Agent**：无额外费用
- **保留期**：默认 30 天，可按需调整

### 故障排除

**问题**：Azure Monitor Agent 显示"失败"状态
```bash
# 解决方案
1. 确认 VM 的托管身份已分配正确的角色（Monitoring Metrics Publisher）
2. 检查 VM 网络连接：curl https://monitor.azure.com
3. 查看 agent 日志：/var/log/waagent.log (Linux) 或 Event Viewer (Windows)
```

**问题**：Log Analytics 中没有数据
```bash
# 解决方案
1. 确认 Log Analytics Workspace 已部署：terraform output log_analytics_workspace_id
2. 等待 2-5 分钟使 Agent 启动
3. 运行查询验证：Perf | take 10
4. 检查诊断设置是否已配置
```

**问题**：查询返回 0 条记录
```bash
# 验证步骤
1. 检查时间范围：TimeGenerated > ago(1h)
2. 验证计算机名称：distinct Computer
3. 查看可用表：search "*" | distinct $table | sort by $table
```

## 后续步骤
1. **配置应用**：在 VM 上部署你的应用（Web 服务器、API、数据库等）
2. **监控和告警**：已自动配置 Azure Monitor（本节内容）
3. **备份**：配置 Azure Backup 定期备份 VM
4. **成本优化**：考虑使用 Reserved Instances 或 Spot VM 降低成本
5. **安全加固**：按需调整安全组规则，仅允许必要的端口
6. **日志分析**：定期检查 Log Analytics 中的性能和安全日志
7. **性能调优**：基于监控数据调整 VM 大小或应用配置
