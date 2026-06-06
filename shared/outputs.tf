output "container_app_environment_id" {
  description = "Teams reference this via data source, not this output directly."
  value       = azurerm_container_app_environment.platform.id
}

output "container_app_environment_name" {
  value = azurerm_container_app_environment.platform.name
}
