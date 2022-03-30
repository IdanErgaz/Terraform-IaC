output "admin_password" {
  value = var.admin_password
}

# output "ip4Okta"{
#   value = azurerm_resource_group.azurerm_public_ip.data  
# }
  
output "current_workspace" {
  value=terraform.workspace
}

output "vmss_front_ip" {
value = "${azurerm_public_ip.vmss.ip_address}"
}

# output "appgw_backend_address_pool_ids" {
#   description = "List of backend address pool Ids."
  # value =[azurerm_lb_backend_address_pool.bpepool.id]
  # value =   data.azurerm_lb_backend_address_pool.vmss.backend_ip_configuration.*.id
  # value       = azurerm_application_gateway.app_gateway.backend_address_pool.*.id

# output "controller_ip"{
#   value=azurerm_network_interface.controller_nic.ip_configuration.private_ip_address
# }
