# SSH 密钥生成 - 快速开始

## 🎯 两种选择

### ✅ 推荐方式：使用本地 SSH 密钥（生产环境）

**优点**：
- 私钥永不进入 Terraform state
- 更安全，符合生产实践
- 密钥在本地受保护

**步骤**：

```bash
# 1. 生成本地 SSH 密钥（如果没有）
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# 2. 配置 terraform.tfvars
generate_ssh_key = false
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# 3. 部署
terraform apply

# 4. 连接 VM
ssh -i ~/.ssh/id_rsa azureuser@<vm_public_ip>
```

---

### 🧪 快速方式：让 Terraform 生成密钥（开发环境）

**警告** ⚠️：私钥会存储在 state 文件中，仅用于开发/测试。

**步骤**：

```bash
# 1. 配置 terraform.tfvars
generate_ssh_key = true

# 2. 部署
terraform apply

# 3. 提取私钥
terraform output -raw ssh_private_key_pem > ~/.ssh/tf_vm_key
chmod 600 ~/.ssh/tf_vm_key

# 4. 连接 VM
ssh -i ~/.ssh/tf_vm_key azureuser@<vm_public_ip>
```

---

## 📋 检查当前配置

```bash
# 查看密钥是否自动生成
terraform output ssh_key_generated

# 查看密钥配置详情（包括任何警告）
terraform output ssh_key_info

# 查看 VM 连接信息
terraform output connection_info
```

---

## 🔐 安全建议

| 场景 | 推荐方式 | 密钥存储位置 |
|------|---------|-----------|
| **生产环境** | 本地密钥 | ~/.ssh/id_rsa（本地，受保护） |
| **测试/开发** | Terraform 生成 | Terraform state（临时） |

### 对于 Terraform 生成方式的额外注意事项：
- ⚠️ 不要提交 state 文件到 Git
- ⚠️ 使用远程后端（Azure Storage、Terraform Cloud）
- ⚠️ 限制访问权限
- ⚠️ 定期轮换

---

## 📚 更多信息

详见 [SSH_KEY_GENERATION_GUIDE.md](SSH_KEY_GENERATION_GUIDE.md)
