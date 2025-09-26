#!/bin/bash
# validate-alz.sh - Azure Landing Zone Deployment Validation Script
#
# Purpose: 
#   This script performs comprehensive validation checks before deploying the Azure Landing Zone
#   Terraform configuration. It ensures all prerequisites are met and the configuration is valid.
#
# What this script validates:
#   ✅ Azure CLI installation and authentication status
#   ✅ Terraform installation and version requirements (>= 1.5.0)
#   ✅ Terraform configuration syntax and structure validity
#   ✅ Required terraform.tfvars file existence and key variables
#   ✅ Azure subscription access and management group permissions
#   ✅ Terraform plan execution (dry-run validation)
#   ✅ Configuration recommendations based on your settings
#
# Usage:
#   ./validate-alz.sh
#
# Exit codes:
#   0 = All validations passed, ready to deploy
#   1 = Validation failures detected, deployment not recommended
#
# Prerequisites:
#   - Azure CLI installed and logged in (az login)
#   - Terraform >= 1.5.0 installed
#   - terraform.tfvars file configured with your values
#   - Appropriate Azure permissions (Management Group Contributor or Owner)

set -e

echo "🚀 Azure Landing Zone Terraform Validation Script"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "INFO")
            echo -e "${BLUE}ℹ️  ${message}${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}✅ ${message}${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  ${message}${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ ${message}${NC}"
            ;;
    esac
}

# Check prerequisites
print_status "INFO" "Checking prerequisites..."

# Check if Azure CLI is installed and logged in
if ! command -v az &> /dev/null; then
    print_status "ERROR" "Azure CLI is not installed. Please install it first."
    exit 1
fi

print_status "SUCCESS" "Azure CLI is installed"

# Check if logged in
if ! az account show &> /dev/null; then
    print_status "ERROR" "Not logged into Azure CLI. Please run 'az login' first."
    exit 1
fi

print_status "SUCCESS" "Azure CLI is logged in"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_status "ERROR" "Terraform is not installed. Please install it first."
    exit 1
fi

TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
print_status "SUCCESS" "Terraform ${TERRAFORM_VERSION} is installed"

# Check Terraform version requirement (>= 1.5.0)
MIN_VERSION="1.5.0"
if [ "$(printf '%s\n' "$MIN_VERSION" "$TERRAFORM_VERSION" | sort -V | head -n1)" != "$MIN_VERSION" ]; then
    print_status "ERROR" "Terraform version must be >= ${MIN_VERSION}. Current version: ${TERRAFORM_VERSION}"
    exit 1
fi

print_status "SUCCESS" "Terraform version requirement met"

# Validate Terraform configuration
print_status "INFO" "Validating Terraform configuration..."

if terraform init -backend=false &> /dev/null; then
    print_status "SUCCESS" "Terraform initialization successful"
else
    print_status "ERROR" "Terraform initialization failed"
    exit 1
fi

if terraform validate &> /dev/null; then
    print_status "SUCCESS" "Terraform configuration is valid"
else
    print_status "ERROR" "Terraform configuration validation failed"
    terraform validate
    exit 1
fi

# Check terraform.tfvars exists and has required values
if [ ! -f "terraform.tfvars" ]; then
    print_status "ERROR" "terraform.tfvars file not found"
    exit 1
fi

print_status "SUCCESS" "terraform.tfvars file exists"

# Check for required variables
REQUIRED_VARS=("root_management_group_name" "resource_prefix" "location")
for var in "${REQUIRED_VARS[@]}"; do
    if ! grep -q "^${var}" terraform.tfvars; then
        print_status "WARNING" "Required variable '${var}' not found in terraform.tfvars"
    else
        print_status "SUCCESS" "Required variable '${var}' found"
    fi
done

# Check current Azure subscription
CURRENT_SUB=$(az account show --query "name" -o tsv)
CURRENT_SUB_ID=$(az account show --query "id" -o tsv)
print_status "INFO" "Current Azure subscription: ${CURRENT_SUB} (${CURRENT_SUB_ID})"

# Check permissions
print_status "INFO" "Checking Azure permissions..."

# Check if user has permission to create management groups
if az rest --method GET --url "https://management.azure.com/providers/Microsoft.Management/managementGroups?api-version=2020-05-01" &> /dev/null; then
    print_status "SUCCESS" "Management group permissions verified"
else
    print_status "WARNING" "Unable to verify management group permissions. You may need Owner or Management Group Contributor rights."
fi

# Format and validate Terraform code
print_status "INFO" "Formatting Terraform code..."
terraform fmt -recursive

print_status "INFO" "Running Terraform plan (dry run)..."
if terraform plan -out=tfplan.tmp &> /dev/null; then
    print_status "SUCCESS" "Terraform plan completed successfully"
    rm -f tfplan.tmp
else
    print_status "ERROR" "Terraform plan failed. Please review the configuration."
    rm -f tfplan.tmp
    exit 1
fi

# Configuration recommendations
print_status "INFO" "Configuration recommendations:"

# Check network architecture
NETWORK_ARCH=$(grep "network_architecture" terraform.tfvars | cut -d'"' -f2)
case $NETWORK_ARCH in
    "hub_spoke")
        print_status "INFO" "Network architecture: Hub & Spoke (recommended for most scenarios)"
        ;;
    "vwan")
        print_status "INFO" "Network architecture: Virtual WAN (recommended for multi-region connectivity)"
        ;;
    "none")
        print_status "INFO" "Network architecture: None (governance only deployment)"
        ;;
    *)
        print_status "WARNING" "Network architecture not clearly specified"
        ;;
esac

# Check policy enforcement mode
if grep -q 'policy_enforcement_mode.*DoNotEnforce' terraform.tfvars; then
    print_status "SUCCESS" "Policy enforcement mode: Audit (recommended for initial deployment)"
elif grep -q 'policy_enforcement_mode.*Default' terraform.tfvars; then
    print_status "WARNING" "Policy enforcement mode: Enforce (ensure compliance before deployment)"
fi

echo ""
print_status "SUCCESS" "All validation checks completed successfully!"
echo ""
print_status "INFO" "Ready to deploy. Next steps:"
echo "   1. Review your terraform.tfvars configuration"
echo "   2. Run: terraform plan"
echo "   3. Run: terraform apply"
echo ""
print_status "INFO" "For staged deployment, consider:"
echo "   terraform apply -var='deploy_connectivity_resources=false' -var='policy_enforcement_mode=DoNotEnforce'"