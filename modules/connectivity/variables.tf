# modules/connectivity/variables.tf - ALZ Connectivity Module Variables

# ============================================================================
# CORE CONFIGURATION
# ============================================================================

variable "connectivity_rg_name" {
  description = "Name of the connectivity resource group"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# NETWORK ARCHITECTURE SELECTION
# ============================================================================

variable "deploy_hub_spoke" {
  description = "Deploy hub and spoke architecture"
  type        = bool
  default     = false
}

variable "deploy_vwan" {
  description = "Deploy Virtual WAN architecture"
  type        = bool
  default     = false
}

# ============================================================================
# HUB & SPOKE CONFIGURATION
# ============================================================================

variable "hub_vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
  default     = "hub-vnet"
}

variable "hub_vnet_address_space" {
  description = "Address space for the hub virtual network"
  type        = list(string)
  default     = ["10.0.0.0/22"]
}

variable "hub_subnets" {
  description = "Map of hub subnet names to their configuration"
  type = map(object({
    address_prefixes = list(string)
    delegations      = optional(list(string), [])
  }))
  default = {
    "snet-shared-services" = {
      address_prefixes = ["10.0.0.0/24"]
    }
    "snet-management" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "AzureBastionSubnet" = {
      address_prefixes = ["10.0.2.0/26"]
    }
    "AzureFirewallSubnet" = {
      address_prefixes = ["10.0.3.0/26"]
    }
  }
}

# ============================================================================
# VIRTUAL WAN CONFIGURATION
# ============================================================================

variable "virtual_wan_name" {
  description = "Name of the Virtual WAN"
  type        = string
  default     = "alz-vwan"
}

variable "virtual_hub_name" {
  description = "Name of the Virtual Hub"
  type        = string
  default     = "alz-vhub"
}

variable "virtual_hub_address_prefix" {
  description = "Address prefix for the virtual hub"
  type        = string
  default     = "10.0.0.0/24"
}

variable "deploy_express_route_gateway" {
  description = "Deploy ExpressRoute gateway in Virtual WAN hub"
  type        = bool
  default     = false
}

variable "deploy_vpn_gateway" {
  description = "Deploy VPN gateway in Virtual WAN hub"
  type        = bool
  default     = false
}

variable "express_route_gateway_name" {
  description = "Name of the ExpressRoute gateway"
  type        = string
  default     = "alz-ergw"
}

variable "vpn_gateway_name" {
  description = "Name of the VPN gateway"
  type        = string
  default     = "alz-vpngw"
}

# ============================================================================
# OPTIONAL NETWORKING FEATURES
# ============================================================================

variable "deploy_azure_firewall" {
  description = "Deploy Azure Firewall"
  type        = bool
  default     = false
}

variable "deploy_azure_bastion" {
  description = "Deploy Azure Bastion (Hub & Spoke only)"
  type        = bool
  default     = false
}