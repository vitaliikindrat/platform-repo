terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_container_app" "this" {
  name                         = "ca-${var.name}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = "Single"

  # The managed identity is pre-provisioned by the platform vending machine
  # with AcrPull already assigned. Team CI has AcrPush but not Owner,
  # so it cannot create role assignments itself — platform does it upfront.
  identity {
    type         = "UserAssigned"
    identity_ids = [var.app_identity_id]
  }

  registry {
    server   = var.acr_login_server
    identity = var.app_identity_id
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.name
      image  = "${var.acr_login_server}/${var.name}:${var.image_tag}"
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = var.target_port

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # Critical: the deploy workflow owns the image tag after first apply.
  # Without ignore_changes, every `terraform apply` resets the image to
  # whatever is in this file — wiping the deploy workflow's update.
  lifecycle {
    ignore_changes = [template]
  }
}
