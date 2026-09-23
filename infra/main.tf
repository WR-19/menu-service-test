terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

variable "environment_name" {
  type = string
}

variable "location" {
  type    = string
  default = "uksouth"
}

variable "app_service_plan_sku" {
  type    = string
  default = "B1"
}

variable "db_password" {
  type      = string
  sensitive = true
}

resource "azurerm_resource_group" "menu_service" {
  name     = "ssp-menu-service-${var.environment_name}"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = "sspacr${var.environment_name}"
  resource_group_name = azurerm_resource_group.menu_service.name
  location            = azurerm_resource_group.menu_service.location
  sku                 = "Basic"
}

resource "azurerm_service_plan" "plan" {
  name                = "ssp-menu-plan-${var.environment_name}"
  resource_group_name = azurerm_resource_group.menu_service.name
  location            = azurerm_resource_group.menu_service.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "ssp-menu-logs-${var.environment_name}"
  resource_group_name = azurerm_resource_group.menu_service.name
  location            = azurerm_resource_group.menu_service.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "appinsights" {
  name                = "ssp-menu-appinsights-${var.environment_name}"
  resource_group_name = azurerm_resource_group.menu_service.name
  location            = azurerm_resource_group.menu_service.location
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  application_type    = "web"
}

resource "azurerm_key_vault" "kv" {
  name                = "ssp-menu-kv-${var.environment_name}"
  resource_group_name = azurerm_resource_group.menu_service.name
  location            = azurerm_resource_group.menu_service.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_linux_web_app" "menu_service" {
  name                = "ssp-menu-service-${var.environment_name}"
  resource_group_name = azurerm_resource_group.menu_service.name
  location            = azurerm_resource_group.menu_service.location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    container_registry_use_managed_identity = true

    application_stack {
      docker_image_name   = "ssp/menu-service:latest"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
    }
  }

  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.appinsights.connection_string
    KEY_VAULT_URI                         = azurerm_key_vault.kv.vault_uri
  }
}

resource "azurerm_role_assignment" "web_app_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.menu_service.identity[0].principal_id
}

resource "azurerm_key_vault_access_policy" "web_app" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.menu_service.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

output "app_service_host_name" {
  value = azurerm_linux_web_app.menu_service.default_hostname
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "app_insights_connection_string" {
  value     = azurerm_application_insights.appinsights.connection_string
  sensitive = true
}
