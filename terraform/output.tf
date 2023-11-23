output "public_ip_address" {
  description = "Adresse ip publique"
  value       = azurerm_public_ip.public_ip_address.ip_address
}