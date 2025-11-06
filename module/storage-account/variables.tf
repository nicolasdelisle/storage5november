variable "name_prefix" {
  description = "Lowercase prefix for the storage account name (only a-z and 0-9)."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{3,60}$", var.name_prefix))
    error_message = "name_prefix must be 3-60 chars of lowercase letters, digits, or hyphens."
  }
}

variable "name_suffix" {
  description = "Optional suffix appended to the prefix BEFORE trimming to 24 chars. Lowercase/digits only recommended."
  type        = string
  default     = ""
}

variable "generate_random_suffix" {
  description = "Append a random alphanumeric suffix to help with global uniqueness."
  type        = bool
  default     = true
}

variable "random_suffix_length" {
  description = "Length of random suffix when generate_random_suffix is true."
  type        = number
  default     = 6
}

variable "resource_group_name" {
  description = "Target resource group name."
  type        = string
}

variable "location" {
  description = "Azure region, e.g., eastus2."
  type        = string
}

variable "account_tier" {
  description = "Account tier: Standard or Premium."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Replication: LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS."
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS","ZRS","GRS","RAGRS","GZRS","RAGZRS"], var.account_replication_type)
    error_message = "Invalid replication type."
  }
}

variable "account_kind" {
  description = "Storage account kind."
  type        = string
  default     = "StorageV2"
  validation {
    condition     = contains(["StorageV2","Storage","BlobStorage","FileStorage","BlockBlobStorage"], var.account_kind)
    error_message = "account_kind must be one of StorageV2, Storage, BlobStorage, FileStorage, BlockBlobStorage."
  }
}

variable "access_tier" {
  description = "Hot or Cool (only for StorageV2)."
  type        = string
  default     = "Hot"
  validation {
    condition     = contains(["Hot","Cool"], var.access_tier)
    error_message = "access_tier must be Hot or Cool."
  }
}

variable "enable_https_traffic_only" {
  description = "Force HTTPS."
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Minimum TLS version."
  type        = string
  default     = "TLS1_2"
  validation {
    condition     = contains(["TLS1_0","TLS1_1","TLS1_2","TLS1_3"], var.min_tls_version)
    error_message = "min_tls_version must be TLS1_0, TLS1_1, TLS1_2, or TLS1_3."
  }
}

variable "allow_blob_public_access" {
  description = "Whether blob public access is allowed."
  type        = bool
  default     = false
}

variable "nfsv3_enabled" {
  description = "Enable NFSv3 (FileStorage only in supported regions)."
  type        = bool
  default     = false
}

variable "large_file_share_enabled" {
  description = "Enable large file shares."
  type        = bool
  default     = false
}

variable "cross_tenant_replication_enabled" {
  description = "Enable Cross-tenant replication."
  type        = bool
  default     = false
}

variable "hns_enabled" {
  description = "Enable hierarchical namespace (ADLS Gen2) – only with StorageV2."
  type        = bool
  default     = false
}

variable "blob_versioning_enabled" {
  description = "Enable blob versioning."
  type        = bool
  default     = false
}

variable "identity_type" {
  description = "Managed identity type."
  type        = string
  default     = "SystemAssigned"
  validation {
    condition     = contains(["SystemAssigned","UserAssigned","SystemAssigned, UserAssigned","None"], var.identity_type)
    error_message = "identity_type must be one of: SystemAssigned, UserAssigned, SystemAssigned, UserAssigned, None."
  }
}

variable "network_rules" {
  description = <<EOT
Optional network rules:
{
  default_action             = "Deny" or "Allow"
  bypass                     = ["AzureServices","Logging","Metrics"]
  ip_rules                   = ["1.2.3.4","5.6.7.0/24"]
  virtual_network_subnet_ids = ["/subscriptions/.../subnets/..."]
}
EOT
  type = object({
    default_action             = string
    bypass                     = optional(list(string))
    ip_rules                   = optional(list(string))
    virtual_network_subnet_ids = optional(list(string))
  })
  default = null
}

variable "containers" {
  description = <<EOT
List of containers to create:
[
  {
    name        = "raw"
    access_type = "private" # or "blob" / "container"
    metadata    = { env = "dev" }
  }
]
EOT
  type = list(object({
    name        = string
    access_type = string
    metadata    = optional(map(string))
  }))
  default = []
  validation {
    condition = alltrue([
      for c in var.containers : contains(["private","blob","container"], c.access_type)
    ])
    error_message = "Each container.access_type must be one of: private, blob, container."
  }
}

variable "lifecycle_rules" {
  description = <<EOT
Single-rule lifecycle config (expandable):
[
  {
    filters = {
      blob_types   = ["blockBlob"]
      prefix_match = ["logs/"]
      tag = {
        name  = "class"
        value = "cold"
      }
    }
    actions = {
      base_blob = {
        tier_to_cool_after_days           = 30
        tier_to_archive_after_days        = 90
        delete_after_days                 = 365
      }
      snapshot = {
        delete_after_days = 30
      }
      version = {
        delete_after_days = 60
      }
    }
  }
]
EOT
  type = list(object({
    filters = object({
      blob_types   = optional(list(string))
      prefix_match = optional(list(string))
      tag          = optional(object({ name = string, value = string }))
    })
    actions = object({
      base_blob = object({
        tier_to_cool_after_days    = optional(number)
        tier_to_archive_after_days = optional(number)
        delete_after_days          = optional(number)
      })
      snapshot = optional(object({
        delete_after_days = optional(number)
      }))
      version = optional(object({
        delete_after_days = optional(number)
      }))
    })
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
