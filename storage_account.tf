module "storage_account" {
  source = "./module/storage-account"

  name_prefix              = var.name_prefix
  name_suffix              = var.name_suffix
  generate_random_suffix   = var.generate_random_suffix
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier
  hns_enabled              = var.hns_enabled
  blob_versioning_enabled  = var.blob_versioning_enabled
  allow_blob_public_access = var.allow_blob_public_access
  containers               = var.containers
  tags                     = var.tags     
}


output "storage_account_name" {
  value = module.storage_account.storage_account_name
}

output "storage_account_id" {
  value = module.storage_account.storage_account_id
}
