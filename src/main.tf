
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.101.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

locals {
  prefix = var.prefix
  location = var.location
  sa_name = var.sa_name
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix}-rg1"
  location = local.location
}

# Create a user assigned identity
resource "azurerm_user_assigned_identity" "umi" {
  location            = azurerm_resource_group.rg.location
  name                = "${local.prefix}-umi1"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create keyvault
resource "azurerm_key_vault" "kv" {
  name                = "${local.prefix}-kv1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled = true
}

# Assigning access policy to the user assigned identity so the key can be used to encrypt/decrypt
resource "azurerm_key_vault_access_policy" "kv_policy_umi" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.umi.principal_id

  secret_permissions = ["Get"]
  key_permissions = [
    "Get",
    "UnwrapKey",
    "WrapKey"
  ]
}

# Assigning access policy to current user so the key can be created
resource "azurerm_key_vault_access_policy" "client" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get"]
  key_permissions = [
    "Get",
    "Create",
    "Delete",
    "List",
    "Restore",
    "Recover",
    "UnwrapKey",
    "WrapKey",
    "Purge",
    "Encrypt",
    "Decrypt",
    "Sign",
    "Verify",
    "GetRotationPolicy",
    "SetRotationPolicy"
  ]
}

# Creating a key in the key vault
resource "azurerm_key_vault_key" "kv_key" {
  name         = "sa-key"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]

  depends_on = [
    azurerm_key_vault_access_policy.client,
    azurerm_key_vault_access_policy.kv_policy_umi
  ]
}

# Creating a storage account with customer managed key
resource "azurerm_storage_account" "sa" {
  name                     = local.sa_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  identity {
    type = "UserAssigned"
    identity_ids = [ azurerm_user_assigned_identity.umi.id ]
  }
  
  customer_managed_key {
    key_vault_key_id = azurerm_key_vault_key.kv_key.id
    user_assigned_identity_id = azurerm_user_assigned_identity.umi.id
  }

  lifecycle {
    ignore_changes = [
      customer_managed_key
    ]
  }
}