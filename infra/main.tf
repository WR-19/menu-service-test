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

resource "azurerm_resource_group" "menu_service" {
  name     = "ssp-menu-service-${var.environment_name}"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = "sspacr${var.environment_name}"
  resource_group_name = azurerm_resource_group.menu_service.name
  location            = azurerm_resource_group.menu_service.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_service_plan" "plan" {
  name                = "ssp-menu-plan-${var.environment_name}"
  resource_group_name = azurerm_resource_group.menu_service.name
  location            = azurerm_resource_group.menu_service.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku
}

resource "azurerm_linux_web_app" "menu_service" {
  name                = "ssp-menu-service-${var.environment_name}"
  resource_group_name = azurerm_resource_group.menu_service.name
  location            = azurerm_resource_group.menu_service.location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = false

  site_config {
    application_stack {
      docker_image_name   = "ssp/menu-service:latest"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
    }
  }
}

output "app_service_host_name" {
  value = azurerm_linux_web_app.menu_service.default_hostname
}
