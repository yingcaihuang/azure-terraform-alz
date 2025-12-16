# outputs.tf in optional_resources module

output "management_resource_group_name" {
  value       = azurerm_resource_group.optional_resources.name
  description = "Name of the resource group created for optional resources"
}

output "log_analytics_workspace_prod_id" {
  value       = var.deploy_log_analytics_workspace ? azurerm_log_analytics_workspace.prod[0].id : ""
  description = "Resource ID of the production Log Analytics Workspace"
}

output "log_analytics_workspace_nonprod_id" {
  value       = var.deploy_log_analytics_workspace ? azurerm_log_analytics_workspace.nonprod[0].id : ""
  description = "Resource ID of the non-production Log Analytics Workspace"
}
