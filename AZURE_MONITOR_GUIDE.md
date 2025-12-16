# Azure Monitor 快速参考指南

## 概述
本项目自动为 VM 配置 Azure Monitor Agent，用于采集系统指标、日志等监控数据。

## 自动配置的内容

### 1. Azure Monitor Agent（AMA）
- **Linux**：`AzureMonitorLinuxAgent` 
- **Windows**：`AzureMonitorWindowsAgent`
- 自动安装并配置为 VM 扩展

### 2. 托管身份
- 创建用户分配的托管身份
- 赋予 `Monitoring Metrics Publisher` 角色
- 用于 Agent 安全地向 Monitor 发送指标

### 3. 诊断设置
- 将 VM 指标发送到 Log Analytics Workspace
- 采集所有平台指标（CPU、内存、磁盘、网络等）
- 采集周期：60 秒

### 4. Log Analytics Workspace
- 自动创建或关联现有工作区
- 保留期：30 天
- 可查询：指标、事件日志、系统日志

## 启用/禁用监控

### 启用（默认）
```hcl
# terraform.tfvars
enable_azure_monitor = true
deploy_log_analytics_workspace = true
```

### 禁用
```hcl
enable_azure_monitor = false
```

## 查看监控数据

### 方法 1：Azure Portal 指标图表
```
搜索框 → "contoso-vm" → 监视 → 指标
选择指标：CPU、内存使用率、磁盘读写等
```

### 方法 2：Log Analytics 查询
```
搜索框 → Log Analytics Workspace → 日志
写入 KQL 查询分析数据
```

### 方法 3：监视器 → 仪表板
```
Azure Portal → Monitor → 仪表板
查看已配置的性能图表
```

## 常用 KQL 查询

### CPU 监控
```kusto
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where InstanceName == "_Total"
| summarize AvgCPU=avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| render timechart
```

### 内存监控
```kusto
Perf
| where ObjectName == "Memory" and CounterName == "Available MBytes"
| summarize MinMem=min(CounterValue) by Computer, bin(TimeGenerated, 5m)
| render timechart
```

### 磁盘监控
```kusto
Perf
| where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
| summarize AvgFreeSpace=avg(CounterValue) by Computer, bin(TimeGenerated, 1h)
| render barchart
```

### 事件日志查询（Windows）
```kusto
Event
| where EventLevelName in ("Error", "Warning")
| where TimeGenerated > ago(24h)
| summarize count() by EventLevelName, Source
| render piechart
```

### 系统日志查询（Linux）
```kusto
Syslog
| where SeverityLevel in ("err", "warning")
| where TimeGenerated > ago(24h)
| summarize count() by Facility, SeverityLevel
| render barchart
```

## 配置告警

### 创建指标告警
```
Azure Portal → Monitor → 告警 → 新建告警规则
选择范围：VM 或 Log Analytics Workspace
选择条件：例如 CPU > 80%
设置操作组：邮件、短信、Webhook 等
```

### 创建日志告警
```kusto
# 告警查询示例：检测高 CPU 使用率
Perf
| where ObjectName == "Processor" 
| where CounterName == "% Processor Time"
| where CounterValue > 80
| where TimeGenerated > ago(5m)
```

## 成本控制

### Log Analytics 定价
- **免费层**：5 GB/月免费数据摄入
- **付费**：超出部分 $2.50/GB
- **保留成本**：超过 31 天保留期按 $0.10/GB/月

### 成本优化建议
1. 调整数据保留期（默认 30 天）
2. 只采集必需的指标和日志
3. 使用日志保留策略删除旧数据

## 故障排除

### Agent 显示"失败"
```bash
# 原因：权限不足或网络无法连接
解决：
1. 检查托管身份是否已分配正确角色
2. 验证 VM 可访问 Monitor 端点
3. 查看 agent 日志进行诊断
```

### Log Analytics 中无数据
```bash
# 原因：Agent 未启动或诊断设置未配置
解决：
1. 等待 2-5 分钟 Agent 启动
2. 检查诊断设置是否正确关联
3. 运行测试查询：Perf | take 1
```

### 查询返回空结果
```bash
# 原因：时间范围不对或计算机名称不匹配
解决：
1. 扩大时间范围：ago(24h) 而不是 ago(1h)
2. 检查计算机名称：distinct Computer
3. 验证数据表名：search "*"
```

## 与 Terraform 的集成

### 查看监控配置
```bash
terraform output vm_monitoring_info
# 输出：
# {
#   "agent_type" = "AzureMonitorLinuxAgent"
#   "log_analytics_enabled" = true
#   "log_analytics_workspace_id" = "/subscriptions/.../workspaces/contoso-prod-..."
#   "managed_identity_id" = "/subscriptions/.../userAssignedIdentities/contoso-vm-monitor-..."
#   "metrics_collection_enabled" = true
#   "monitor_enabled" = true
# }
```

### 获取 Log Analytics Workspace ID
```bash
terraform output log_analytics_workspace_id
```

### 修改监控配置
编辑 `terraform.tfvars`，然后运行：
```bash
terraform plan
terraform apply
```

## 高级配置

### 自定义指标采集频率
修改 Data Collection Rule (DCR)，改变采集间隔（默认 60 秒）

### 添加自定义日志源
在 DCR 中配置额外的日志路径或事件源

### 集成告警系统
配置 Action Groups，与 PagerDuty、Slack、Teams 等集成

## 参考资源
- [Azure Monitor Agent 文档](https://docs.microsoft.com/azure/azure-monitor/agents/agents-overview)
- [Log Analytics KQL 参考](https://docs.microsoft.com/azure/data-explorer/kusto/query/)
- [Azure Monitor 定价](https://azure.microsoft.com/en-us/pricing/details/monitor/)
- [最佳实践指南](https://docs.microsoft.com/azure/azure-monitor/best-practices-agent)
