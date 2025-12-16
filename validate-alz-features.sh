#!/bin/bash
# validate-alz-features.sh - 完整功能验证脚本

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔍 Azure Landing Zone - 功能完整验证"
echo "======================================="
echo ""

PASSED=0
WARNINGS=0

# 1. Compute 模块
echo "1️⃣  COMPUTE 模块检查"
if grep -q "deploy_compute_resources.*true" terraform.tfvars; then
    echo -e "${GREEN}✅ Compute${NC}: 已启用"
    ((PASSED++))
    
    grep "vm_os_type" terraform.tfvars | head -1 && ((PASSED++))
    grep "vm_size" terraform.tfvars | head -1 && ((PASSED++))
    
    if grep -q "assign_public_ip.*true" terraform.tfvars; then
        echo -e "${GREEN}✅ 公网 IP${NC}: 已配置"
        ((PASSED++))
    fi
else
    echo -e "${BLUE}ℹ️  Compute${NC}: 已禁用"
fi

echo ""
echo "2️⃣  SSH 密钥配置"
if grep -q "generate_ssh_key.*true" terraform.tfvars; then
    echo -e "${GREEN}✅ SSH 密钥生成${NC}: 由 Terraform 生成"
    echo -e "${YELLOW}⚠️  安全提示${NC}: 私钥存储在 State 中，需要保护"
    ((PASSED++))
    ((WARNINGS++))
else
    echo -e "${BLUE}ℹ️  SSH 密钥生成${NC}: 使用本地密钥"
    if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        echo -e "${GREEN}✅ 本地密钥${NC}: 找到 ~/.ssh/id_rsa.pub"
        ((PASSED++))
    fi
fi

echo ""
echo "3️⃣  Azure Monitor 配置"
if grep -q "enable_azure_monitor.*true" terraform.tfvars; then
    echo -e "${GREEN}✅ Monitor Agent${NC}: 已启用"
    ((PASSED++))
    
    if grep -q "deploy_log_analytics_workspace.*true" terraform.tfvars; then
        echo -e "${GREEN}✅ Log Analytics${NC}: 将创建工作区"
        ((PASSED++))
    fi
else
    echo -e "${BLUE}ℹ️  Monitor Agent${NC}: 已禁用"
fi

echo ""
echo "4️⃣  网络和策略配置"
if grep -q 'network_architecture.*"hub_spoke"' terraform.tfvars; then
    echo -e "${GREEN}✅ 网络架构${NC}: Hub & Spoke"
    ((PASSED++))
fi

if grep -q "deploy_policies.*true" terraform.tfvars; then
    echo -e "${GREEN}✅ 策略部署${NC}: 已启用"
    ((PASSED++))
fi

echo ""
echo "═════════════════════════════════════════"
echo "📊 验证结果"
echo -e "${GREEN}✅ 通过检查: $PASSED${NC}"
if [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  警告: $WARNINGS${NC}"
fi
echo "═════════════════════════════════════════"
echo ""
echo -e "${GREEN}✅ 功能验证完成！${NC}"
