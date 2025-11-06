terraform {
  required_version = ">= 1.4.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

locals {
  base_name = lower(replace("${var.name_prefix}${var.name_suffix}", "/[^a-z0-9]/", ""))
  # Ensure global uniqueness if requested; SA name must be 3-24 chars, lowercase, unique
  composed_name = (var.generate_random_suffix
    ? lower(substr("${local.base_name}${random_string.sa_suffix[0].result}", 0, 24))
    : lower(substr(local.base_name, 0, 24))
  )
}

resource "random_string" "sa_suffix" {
  count  = var.generate_random_suffix ? 1 : 0
  length = var.random_suffix_length
  upper  = false
  lower  = true
  numeric = true
  special = false
}

resource "azurerm_storage_account" "this" {
  name                     = local.composed_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  access_tier              = var.account_kind == "StorageV2" ? var.access_tier : null

  https_traffic_only_enabled   = var.enable_https_traffic_only
  min_tls_version             = var.min_tls_version
  allow_nested_items_to_be_public    = var.allow_blob_public_access
  nfsv3_enabled               = var.nfsv3_enabled
  large_file_share_enabled    = var.large_file_share_enabled
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled

  # Data Lake Gen2 (ADLS) – only valid for StorageV2
  is_hns_enabled = var.hns_enabled

  blob_properties {
    versioning_enabled = var.blob_versioning_enabled
  }

  dynamic "network_rules" {
    for_each = var.network_rules == null ? [] : [var.network_rules]
    content {
      default_action             = network_rules.value.default_action
      bypass                     = coalesce(network_rules.value.bypass, [])
      ip_rules                   = coalesce(network_rules.value.ip_rules, [])
      virtual_network_subnet_ids = coalesce(network_rules.value.virtual_network_subnet_ids, [])
    }
  }

  identity {
    type = var.identity_type
  }

  tags = var.tags
}

# Optional: create containers
resource "azurerm_storage_container" "containers" {
  for_each              = { for c in var.containers : c.name => c }
  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = each.value.access_type
  metadata              = try(each.value.metadata, null)
}

# Optional: lifecycle / tiering rules
resource "azurerm_storage_management_policy" "this" {
  count               = length(var.lifecycle_rules) > 0 ? 1 : 0
  storage_account_id  = azurerm_storage_account.this.id

  rule {
    name    = "rule-0"
    enabled = true
    filters {
      blob_types   = try(var.lifecycle_rules[0].filters.blob_types, ["blockBlob"])
      prefix_match = try(var.lifecycle_rules[0].filters.prefix_match, null)
      match_blob_index_tag {
        name  = try(var.lifecycle_rules[0].filters.tag.name, null)
        value = try(var.lifecycle_rules[0].filters.tag.value, null)
      }
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = try(var.lifecycle_rules[0].actions.base_blob.tier_to_cool_after_days, null)
        tier_to_archive_after_days_since_modification_greater_than = try(var.lifecycle_rules[0].actions.base_blob.tier_to_archive_after_days, null)
        delete_after_days_since_modification_greater_than          = try(var.lifecycle_rules[0].actions.base_blob.delete_after_days, null)
      }
      snapshot {
        delete_after_days_since_creation_greater_than = try(var.lifecycle_rules[0].actions.snapshot.delete_after_days, null)
      }
      version {
        delete_after_days_since_creation = try(var.lifecycle_rules[0].actions.version.delete_after_days, null)
      }
    }
  }

  lifecycle {
    ignore_changes = [rule] # allows you to change list shape without replacement; expand as needed
  }
}
