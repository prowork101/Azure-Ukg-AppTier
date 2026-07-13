output "resource_group_name" {
  value = azurerm_resource_group.ukg.name
}

output "location" {
  value = azurerm_resource_group.ukg.location
}
output "virtual_network_name" {
  value = azurerm_virtual_network.ukg.name
}

output "application_gateway_subnet_id" {
  value = azurerm_subnet.application_gateway.id
}

output "application_subnet_id" {
  value = azurerm_subnet.application.id
}

output "data_subnet_id" {
  value = azurerm_subnet.data.id
}

output "application_public_ip" {
  description = "Public IP address of the application VM"
  value       = azurerm_public_ip.application.ip_address
}

output "sql_server_name" {
  value = azurerm_mssql_server.database.name
}

output "sql_database_name" {
  value = azurerm_mssql_database.database.name
}