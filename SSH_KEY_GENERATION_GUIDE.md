# SSH 密钥生成指南

## 概述

Terraform 现在支持自动生成 SSH 密钥对，无需提前准备本地 SSH 密钥文件。此功能由新的 `generate_ssh_key` 变量控制。

## 使用场景

### 场景 1：使用本地 SSH 密钥（推荐用于生产环境）

如果您已有 SSH 密钥对，使用本地密钥文件是更安全的做法。

**配置方式**（terraform.tfvars）：
```terraform
generate_ssh_key = false
ssh_public_key_path = "~/.ssh/id_rsa.pub"  # 您的本地公钥路径
```

**优点**：
- 私钥永不进入 Terraform state 文件
- 密钥已在本地安全保存
- 适合生产环境部署

**步骤**：
1. 生成本地 SSH 密钥（如果没有）：
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```

2. 设置 `generate_ssh_key = false`

3. 运行 Terraform：
   ```bash
   terraform apply
   ```

4. 使用本地私钥连接 VM：
   ```bash
   ssh -i ~/.ssh/id_rsa azureuser@<vm_public_ip>
   ```

### 场景 2：让 Terraform 生成 SSH 密钥（快速部署）

让 Terraform 生成新的 SSH 密钥对，适合测试和开发环境。

**配置方式**（terraform.tfvars）：
```terraform
generate_ssh_key = true
```

**重要警告**：
- ⚠️ 生成的私钥将存储在 Terraform state 文件中
- ⚠️ State 文件包含敏感信息，必须妥善保护
- ⚠️ 不推荐用于生产环境

**步骤**：

1. 设置 `generate_ssh_key = true`

2. 运行 Terraform：
   ```bash
   terraform apply
   ```

3. Terraform 将显示生成的公钥（不显示私钥以保护安全）

4. **提取私钥**（仅在需要时）：

   ```bash
   # 获取私钥
   terraform output -raw ssh_private_key_pem > ~/.ssh/terraform_vm_key
   
   # 设置正确权限
   chmod 600 ~/.ssh/terraform_vm_key
   
   # 使用私钥连接
   ssh -i ~/.ssh/terraform_vm_key azureuser@<vm_public_ip>
   ```

5. **查看密钥生成状态**：
   ```bash
   terraform output ssh_key_info
   ```

## 查看密钥信息

### 查看是否启用了密钥生成
```bash
terraform output ssh_key_generated
```

### 查看密钥配置摘要
```bash
terraform output ssh_key_info
```

输出示例：
```json
{
  "key_generation_enabled" = true
  "key_source" = "Terraform (tls_private_key)"
  "warning" = "Private key is stored in Terraform state file..."
}
```

### 查看公钥（仅当生成密钥时）
```bash
terraform output ssh_public_key_openssh
```

### 获取私钥（仅当生成密钥时）
```bash
terraform output ssh_private_key_pem
```

## 连接 VM 的方式

### 使用本地 SSH 密钥（generate_ssh_key = false）
```bash
ssh -i ~/.ssh/id_rsa azureuser@<public_ip>
```

### 使用 Terraform 生成的密钥（generate_ssh_key = true）

**第一步：从 Terraform state 提取私钥**
```bash
terraform output -raw ssh_private_key_pem > ~/.ssh/tf_vm_key
chmod 600 ~/.ssh/tf_vm_key
```

**第二步：连接 VM**
```bash
ssh -i ~/.ssh/tf_vm_key azureuser@<public_ip>
```

**查看连接命令模板**
```bash
terraform output connection_info
```

## 安全最佳实践

### 对于本地密钥方式（generate_ssh_key = false）

✅ **推荐做法**：
- 使用已有的安全生成的 SSH 密钥
- 定期轮换密钥
- 限制密钥文件权限（600）
- 在 SSH 密钥上设置密码保护

```bash
# 设置 SSH 密钥权限
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### 对于 Terraform 生成方式（generate_ssh_key = true）

⚠️ **关键安全考虑**：

1. **保护 State 文件**
   - State 文件包含私钥，需要严格保护
   - 启用 state 加密（使用远程后端）
   - 限制访问权限

2. **远程后端配置（推荐）**
   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "rg-terraform-state"
       storage_account_name = "stname"
       container_name       = "tfstate"
       key                  = "prod.tfstate"
     }
   }
   ```

3. **提取并安全存储私钥**
   ```bash
   # 从 state 提取
   terraform output -raw ssh_private_key_pem > ~/.ssh/terraform_vm_key
   
   # 立即删除 terraform state
   # （如果使用本地后端）
   rm -f terraform.tfstate terraform.tfstate.backup
   ```

4. **密钥轮换**
   - 如需轮换，运行：
     ```bash
     terraform taint 'module.compute.tls_private_key.vm_key'
     terraform apply
     ```

5. **不要**：
   - 将 terraform state 提交到 Git
   - 在公开 Repository 中放置 state 文件
   - 与他人分享生成的私钥
   - 在生产环境中使用 Terraform 生成的密钥

## 配置示例

### 示例 1：快速开发环境（生成密钥）
```terraform
# terraform.tfvars
deploy_compute_resources = true
vm_os_type               = "linux"
generate_ssh_key         = true  # 让 Terraform 生成
admin_username           = "azureuser"
enable_azure_monitor     = true
assign_public_ip         = true
```

### 示例 2：生产环境（使用本地密钥）
```terraform
# terraform.tfvars
deploy_compute_resources = true
vm_os_type               = "linux"
generate_ssh_key         = false  # 使用本地密钥
ssh_public_key_path      = "/var/secrets/keys/prod_rsa.pub"
admin_username           = "azureuser"
enable_azure_monitor     = true
assign_public_ip         = true
```

## 故障排查

### 问题 1：提取私钥时出现 "sensitive output" 错误
```bash
# 正确做法：使用 -raw 标志
terraform output -raw ssh_private_key_pem > key.pem
```

### 问题 2：连接时 "Permission denied (publickey)"
```bash
# 检查私钥权限
ls -la ~/.ssh/terraform_vm_key
chmod 600 ~/.ssh/terraform_vm_key

# 启用详细 SSH 日志排查
ssh -vvv -i ~/.ssh/terraform_vm_key azureuser@<ip>
```

### 问题 3：terraform apply 后仍显示旧私钥
```bash
# 强制刷新密钥
terraform taint 'module.compute.tls_private_key.vm_key[0]'
terraform apply
```

## 命令快速参考

```bash
# 查看密钥生成状态
terraform output ssh_key_generated

# 查看密钥配置信息
terraform output ssh_key_info

# 查看公钥（生成模式）
terraform output ssh_public_key_openssh

# 提取私钥（生成模式）
terraform output -raw ssh_private_key_pem > key.pem

# 查看连接信息
terraform output connection_info

# 强制重新生成密钥
terraform taint 'module.compute.tls_private_key.vm_key[0]'
terraform apply

# 查看 VM 详情
terraform output vm_name
terraform output vm_public_ip
```

## 变量总结

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `generate_ssh_key` | `false` | 是否让 Terraform 生成 SSH 密钥对 |
| `ssh_public_key_path` | `~/.ssh/id_rsa.pub` | 本地 SSH 公钥路径（当 generate_ssh_key=false 时使用） |
| `deploy_compute_resources` | 根据部署 | 是否部署计算资源（包括 VM） |

## 相关输出

- `ssh_key_generated` - 是否生成了密钥
- `ssh_private_key_pem` - 私钥（生成模式，sensitive）
- `ssh_public_key_openssh` - 公钥（生成模式）
- `ssh_key_info` - 密钥配置摘要
- `connection_info` - VM 连接信息

---

**更新日期**: 2025-09-26  
**相关文档**: [VM 部署指南](VM_DEPLOYMENT_GUIDE.md), [快速参考](QUICK_REFERENCE.md)
