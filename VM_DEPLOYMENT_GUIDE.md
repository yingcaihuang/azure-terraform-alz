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

## 后续步骤
1. **配置应用**：在 VM 上部署你的应用（Web 服务器、API、数据库等）
2. **监控和告警**：配置 Azure Monitor 采集 VM 指标
3. **备份**：配置 Azure Backup 定期备份 VM
4. **成本优化**：考虑使用 Reserved Instances 或 Spot VM 降低成本
5. **安全加固**：按需调整安全组规则，仅允许必要的端口
