# modules/compute/outputs.tf - Compute Module Outputs

output "resource_group_name" {
  description = "Name of the compute resource group"
  value       = var.deploy_compute_resources ? azurerm_resource_group.compute[0].name : null
}

output "resource_group_id" {
  description = "ID of the compute resource group"
  value       = var.deploy_compute_resources ? azurerm_resource_group.compute[0].id : null
}

output "vm_id" {
  description = "ID of the virtual machine"
  value       = var.vm_os_type == "linux" ? (var.deploy_compute_resources ? azurerm_linux_virtual_machine.vm[0].id : null) : (var.deploy_compute_resources ? azurerm_windows_virtual_machine.vm_windows[0].id : null)
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = var.vm_os_type == "linux" ? (var.deploy_compute_resources ? azurerm_linux_virtual_machine.vm[0].name : null) : (var.deploy_compute_resources ? azurerm_windows_virtual_machine.vm_windows[0].name : null)
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = var.deploy_compute_resources ? azurerm_network_interface.vm_nic[0].private_ip_address : null
}

output "vm_public_ip" {
  description = "Public IP address of the VM (if assigned)"
  value       = var.assign_public_ip && var.deploy_compute_resources ? azurerm_public_ip.vm_public_ip[0].ip_address : null
}

output "vm_public_ip_id" {
  description = "ID of the public IP address"
  value       = var.assign_public_ip && var.deploy_compute_resources ? azurerm_public_ip.vm_public_ip[0].id : null
}

output "network_security_group_id" {
  description = "ID of the network security group"
  value       = var.deploy_compute_resources ? azurerm_network_security_group.vm_nsg[0].id : null
}

output "network_security_group_name" {
  description = "Name of the network security group"
  value       = var.deploy_compute_resources ? azurerm_network_security_group.vm_nsg[0].name : null
}

output "network_interface_id" {
  description = "ID of the network interface"
  value       = var.deploy_compute_resources ? azurerm_network_interface.vm_nic[0].id : null
}

output "connection_info" {
  description = "Connection information for the VM"
  value = var.deploy_compute_resources ? {
    os_type    = var.vm_os_type
    private_ip = azurerm_network_interface.vm_nic[0].private_ip_address
    public_ip  = var.assign_public_ip ? azurerm_public_ip.vm_public_ip[0].ip_address : "N/A"
    username   = var.admin_username
    ssh_command = var.vm_os_type == "linux" && var.assign_public_ip ? "ssh -i <your_private_key> ${var.admin_username}@${azurerm_public_ip.vm_public_ip[0].ip_address}" : "N/A"
  } : null
}
