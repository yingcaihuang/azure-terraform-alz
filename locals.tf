# locals.tf - Azure Landing Zone Computed Values

locals {
  # ============================================================================
  # RESOURCE NAMING CONVENTIONS
  # ============================================================================

  # Core naming pattern following Azure naming best practices
  naming_prefix = var.resource_prefix

  # Resource group naming
  connectivity_rg_name = "${local.naming_prefix}-connectivity-${var.location}-rg"
  management_rg_name   = "${local.naming_prefix}-management-${var.location}-rg"
  identity_rg_name     = "${local.naming_prefix}-identity-${var.location}-rg"

  # ============================================================================
  # NETWORKING CONFIGURATION
  # ============================================================================

  # Hub & Spoke Resources
  hub_vnet_name = "${local.naming_prefix}-hub-${var.location}-vnet"

  # Virtual WAN Resources  
  virtual_wan_name           = var.virtual_wan_name != "" ? var.virtual_wan_name : "${local.naming_prefix}-${var.location}-vwan"
  virtual_hub_name           = "${local.naming_prefix}-${var.location}-vhub"
  express_route_gateway_name = "${local.naming_prefix}-${var.location}-ergw"
  vpn_gateway_name           = "${local.naming_prefix}-${var.location}-vpngw"

  # Network architecture decision logic
  deploy_hub_spoke = var.network_architecture == "hub_spoke" && var.deploy_connectivity_resources
  deploy_vwan      = var.network_architecture == "vwan" && var.deploy_connectivity_resources
  deploy_network   = var.deploy_connectivity_resources && var.network_architecture != "none"

  # ============================================================================
  # MANAGEMENT AND MONITORING
  # ============================================================================

  # Log Analytics Workspaces
  log_analytics_workspace_prod_name    = "${local.naming_prefix}-prod-${var.location}-law"
  log_analytics_workspace_nonprod_name = "${local.naming_prefix}-nonprod-${var.location}-law"

  # Automation Account
  automation_account_name = "${local.naming_prefix}-${var.location}-aa"

  # Data Collection Rules
  data_collection_rule_name = "${local.naming_prefix}-${var.location}-dcr"

  # Managed Identity
  managed_identity_name = "${local.naming_prefix}-${var.location}-mi"

  # ============================================================================
  # POLICY CONFIGURATION
  # ============================================================================

  # Core security policies - These are the essential policies for basic security
  # Not the full ALZ/CIS policy suite which can be overwhelming
  core_security_policies = var.deploy_core_policies ? [
    {
      name         = "require-storage-https"
      display_name = "Secure transfer to storage accounts should be enabled"
      description  = "Audit requirement of Secure transfer in your storage account. Secure transfer is an option that forces your storage account to accept requests only from secure connections (HTTPS). Use of HTTPS ensures authentication between the server and the service and protects data in transit from network layer attacks such as man-in-the-middle, eavesdropping, and session-hijacking"
      policy_type  = "BuiltIn"
      mode         = "Indexed"
      policy_rule  = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
    },
    {
      name         = "require-sql-encryption"
      display_name = "Transparent Data Encryption on SQL databases should be enabled"
      description  = "Transparent data encryption should be enabled to protect data-at-rest and meet compliance requirements"
      policy_type  = "BuiltIn"
      mode         = "Indexed"
      policy_rule  = "/providers/Microsoft.Authorization/policyDefinitions/17k78e20-9358-41c9-923c-fb736d382a12"
    },
    {
      name         = "require-vm-backup"
      display_name = "Azure Backup should be enabled for Virtual Machines"
      description  = "Ensure protection of your Azure Virtual Machines by enabling Azure Backup. Azure Backup is a secure and cost effective data protection solution for Azure."
      policy_type  = "BuiltIn"
      mode         = "Indexed"
      policy_rule  = "/providers/Microsoft.Authorization/policyDefinitions/013e242c-8828-4970-87b3-ab247555486d"
    },
    {
      name         = "allowed-locations"
      display_name = "Allowed locations"
      description  = "This policy enables you to restrict the locations your organization can specify when deploying resources. Use to enforce your geo-compliance requirements."
      policy_type  = "BuiltIn"
      mode         = "Indexed"
      policy_rule  = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
    },
    {
      name         = "require-resource-tags"
      display_name = "Require a tag and its value on resource groups"
      description  = "Enforces a required tag and its value on resource groups."
      policy_type  = "BuiltIn"
      mode         = "All"
      policy_rule  = "/providers/Microsoft.Authorization/policyDefinitions/8ce3da23-7156-49e4-b145-24f95f9dcb46"
    }
  ] : []

  # ============================================================================
  # COMPUTED VALUES
  # ============================================================================

  # Subscription assignments for management groups
  subscription_assignments = {
    connectivity = var.connectivity_subscription_id
    identity     = var.identity_subscription_id
    management   = var.management_subscription_id
  }

  # Resource deployment flags
  deployment_flags = {
    connectivity_resources  = var.deploy_connectivity_resources
    log_analytics_workspace = var.deploy_log_analytics_workspace
    automation_account      = var.deploy_automation_account
    data_collection_rules   = var.deploy_data_collection_rules
    managed_identity        = var.deploy_managed_identity
    core_policies           = var.deploy_core_policies
  }

  # Combined tags for all resources
  common_tags = merge(var.tags, {
    DeployedBy          = "ALZ-Terraform"
    LastUpdated         = timestamp()
    NetworkArchitecture = var.network_architecture
  })
}