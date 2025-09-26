# modules/core_policies/variables.tf - ALZ Core Policies Module Variables

# ============================================================================
# CORE POLICY CONFIGURATION
# ============================================================================

variable "deploy_core_policies" {
  description = "Deploy core security and compliance policies"
  type        = bool
  default     = true
}

variable "policy_enforcement_mode" {
  description = "Policy enforcement mode: 'DoNotEnforce' for audit mode, 'Default' for enforce mode"
  type        = string
  default     = "DoNotEnforce"
  validation {
    condition     = contains(["DoNotEnforce", "Default"], var.policy_enforcement_mode)
    error_message = "Policy enforcement mode must be either 'DoNotEnforce' or 'Default'."
  }
}

# ============================================================================
# MANAGEMENT GROUP IDS
# ============================================================================

variable "root_management_group_id" {
  description = "ID of the root management group"
  type        = string
}

variable "platform_management_group_id" {
  description = "ID of the Platform management group"
  type        = string
}

variable "landing_zones_management_group_id" {
  description = "ID of the Landing Zones management group"
  type        = string
}

variable "sandbox_management_group_id" {
  description = "ID of the Sandbox management group"
  type        = string
}

# ============================================================================
# POLICY PARAMETERS
# ============================================================================

variable "allowed_locations" {
  description = "List of allowed Azure locations for resource deployment"
  type        = list(string)
  default     = ["westus3", "eastus2", "centralus"]
}

variable "required_environment_tag" {
  description = "Required value for the Environment tag"
  type        = string
  default     = "ALZ"
}

# ============================================================================
# POLICY INITIATIVE CONFIGURATION
# ============================================================================

variable "create_policy_initiative" {
  description = "Create a custom policy initiative (policy set) grouping core security policies"
  type        = bool
  default     = true
}

# ============================================================================
# EXEMPTION CONFIGURATION
# ============================================================================

variable "create_sandbox_exemptions" {
  description = "Create policy exemptions for sandbox environments"
  type        = bool
  default     = true
}

variable "sandbox_exemption_expiry" {
  description = "Expiration date for sandbox policy exemptions (YYYY-MM-DD)"
  type        = string
  default     = null
  validation {
    condition     = var.sandbox_exemption_expiry == null || can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", var.sandbox_exemption_expiry))
    error_message = "Exemption expiry must be in YYYY-MM-DD format or null."
  }
}