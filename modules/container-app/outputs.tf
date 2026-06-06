output "url" {
  description = "Public HTTPS endpoint of the Container App."
  value       = "https://${azurerm_container_app.this.ingress[0].fqdn}"
}

output "id" {
  description = "Resource ID. Use this if another module needs to assign roles to this app."
  value       = azurerm_container_app.this.id
}

output "name" {
  description = "Full resource name (ca-{var.name}). Needed by the deploy workflow."
  value       = azurerm_container_app.this.name
}
