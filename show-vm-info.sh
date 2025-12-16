#!/bin/bash

# 快速查看部署后 VM 和 Monitor 信息的脚本

set -e

echo "=========================================="
echo "Azure Landing Zone - VM 和 Monitor 信息"
echo "=========================================="
echo ""

echo "📊 VM 部署信息："
echo "---"
terraform output -json vm_info 2>/dev/null | jq '.' || echo "VM 未部署或未初始化"
echo ""

echo "📱 VM 网络信息："
echo "---"
echo "公网 IP：$(terraform output -raw vm_public_ip 2>/dev/null || echo 'N/A')"
echo "私网 IP：$(terraform output -raw vm_private_ip 2>/dev/null || echo 'N/A')"
echo "资源组：$(terraform output -raw vm_resource_group_name 2>/dev/null || echo 'N/A')"
echo ""

echo "🔐 安全组信息："
echo "---"
terraform output -json security_group_info 2>/dev/null | jq '.' || echo "安全组信息不可用"
echo ""

echo "📈 Azure Monitor 配置："
echo "---"
terraform output -json vm_monitoring_info 2>/dev/null | jq '.' || echo "Monitor 未配置"
echo ""

echo "📊 Log Analytics Workspace："
echo "---"
LAW_ID=$(terraform output -raw log_analytics_workspace_id 2>/dev/null || echo "")
if [ -z "$LAW_ID" ]; then
  echo "Workspace ID：未部署"
else
  echo "Workspace ID：$LAW_ID"
  # 提取 Workspace 名称
  WS_NAME=$(echo "$LAW_ID" | grep -oP 'workspaces/\K[^/]+' || echo "N/A")
  echo "Workspace 名称：$WS_NAME"
fi
echo ""

echo "🔗 快速链接："
echo "---"
PUBLIC_IP=$(terraform output -raw vm_public_ip 2>/dev/null || echo "")
if [ ! -z "$PUBLIC_IP" ]; then
  echo "HTTP：http://$PUBLIC_IP"
  echo "HTTPS：https://$PUBLIC_IP"
fi
echo ""

echo "📚 文档："
echo "---"
echo "VM 部署指南：VM_DEPLOYMENT_GUIDE.md"
echo "Monitor 参考：AZURE_MONITOR_GUIDE.md"
echo "完成总结：COMPLETION_SUMMARY.md"
echo ""

echo "✅ 部署信息查询完成"
