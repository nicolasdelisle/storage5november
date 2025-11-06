output "storage_account_id" {
  description = "Resource ID of the Storage Account."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the Storage Account."
  value       = azurerm_storage_account.this.name
}

output "primary_endpoints" {
  description = "Primary endpoints for services."
  value = {
    blob  = azurerm_storage_account.this.primary_blob_endpoint
    queue = azurerm_storage_account.this.primary_queue_endpoint
    table = azurerm_storage_account.this.primary_table_endpoint
    file  = azurerm_storage_account.this.primary_file_endpoint
    web   = azurerm_storage_account.this.primary_web_endpoint
    dfs   = azurerm_storage_account.this.primary_dfs_endpoint
  }
}

output "container_names" {
  description = "Created container names."
  value       = keys(azurerm_storage_container.containers)
}
