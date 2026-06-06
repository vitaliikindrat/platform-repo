# ── team-demo ────────────────────────────────────────────────────────────────
# Everything a team needs to ship containers on the platform.
# Run once via the onboard workflow. Team never touches this file.
# ─────────────────────────────────────────────────────────────────────────────

locals {
  team = "demo"
  # Convention: team's github org/user + repo name. Must match exactly.
  github_owner = "vitaliikindrat"
  github_repo  = "team-demo"
}

# Team's resource group. Their blast radius: everything inside here.
# Cannot affect rg-platform-shared, rg-oidc-demo, or other teams' RGs.
resource "azurerm_resource_group" "team_demo" {
  name     = "rg-team-${local.team}"
  location = "westeurope"
}

# CI identity for the team. This is what their GitHub Actions workflows
# authenticate as. Has no client secret — OIDC only.
resource "azuread_application" "team_demo_ci" {
  display_name = "sp-ci-team-${local.team}"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "team_demo_ci" {
  client_id = azuread_application.team_demo_ci.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

# Federated credential for the prod environment.
# Subject format with environment: "repo:owner/repo:environment:prod"
# This is different from branch format: "repo:owner/repo:ref:refs/heads/main"
# When a job sets `environment: prod`, GitHub changes the sub claim.
# Azure validates exact match — wrong format = 401.
resource "azuread_application_federated_identity_credential" "team_demo_prod" {
  application_id = azuread_application.team_demo_ci.id
  display_name   = "github-env-prod"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_owner}/${local.github_repo}:environment:prod"
  audiences      = ["api://AzureADTokenExchange"]
}

# PR credential — plan runs on PRs, apply only on prod environment.
resource "azuread_application_federated_identity_credential" "team_demo_prs" {
  application_id = azuread_application.team_demo_ci.id
  display_name   = "github-prs"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_owner}/${local.github_repo}:pull_request"
  audiences      = ["api://AzureADTokenExchange"]
}

# Contributor on team RG: can create/update/delete resources, cannot write role assignments.
# This is the ceiling. Team CI can never exceed this.
resource "azurerm_role_assignment" "team_demo_contributor" {
  scope                = azurerm_resource_group.team_demo.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.team_demo_ci.object_id
}

# AcrPush on the shared ACR: can push images, cannot change ACR config or pull from other repos.
resource "azurerm_role_assignment" "team_demo_acr_push" {
  scope                = data.azurerm_container_registry.shared.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.team_demo_ci.object_id
}

# Storage Blob Data Contributor scoped to the tfstate account only.
# Team can read/write their own state key (team-demo-infra.tfstate).
# They cannot list other keys or manage the storage account itself.
# Data plane: read/write blobs (the actual state file content)
resource "azurerm_role_assignment" "team_demo_tfstate_data" {
  scope                = data.azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.team_demo_ci.object_id
}

# ARM plane: read storage account metadata so the backend can resolve
# the blob endpoint. Storage Blob Data Contributor is data-plane only
# and doesn't include Microsoft.Storage/storageAccounts/read.
resource "azurerm_role_assignment" "team_demo_tfstate_reader" {
  scope                = data.azurerm_storage_account.tfstate.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.team_demo_ci.object_id
}

# Managed identity for the running app — separate from CI identity.
# CI pushes images. The app pulls them. Different identities, different roles.
# Platform pre-creates this because team CI has no role assignment permission.
# If team tried to create the AcrPull assignment themselves, ARM returns 403.
resource "azurerm_user_assigned_identity" "team_demo_app" {
  name                = "id-team-${local.team}-app"
  resource_group_name = azurerm_resource_group.team_demo.name
  location            = azurerm_resource_group.team_demo.location
}

resource "azurerm_role_assignment" "team_demo_app_acr_pull" {
  scope                = data.azurerm_container_registry.shared.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.team_demo_app.principal_id
}

# Outputs — these values go into team-demo's GitHub environment secrets.
# After onboard workflow runs, platform copies these to the team's repo.
# Reader on rg-platform-shared so the team's Terraform can resolve shared
# resources via data sources (CAE, Log Analytics, etc.). Read-only —
# team cannot create, update, or delete anything in the platform RG.
resource "azurerm_role_assignment" "team_demo_platform_reader" {
  scope                = data.azurerm_resource_group.platform_shared.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.team_demo_ci.object_id
}

output "team_demo_client_id" {
  description = "→ GitHub secret AZURE_CLIENT_ID in team-demo prod environment"
  value       = azuread_application.team_demo_ci.client_id
}

output "team_demo_resource_group" {
  description = "→ GitHub secret RESOURCE_GROUP in team-demo prod environment"
  value       = azurerm_resource_group.team_demo.name
}

output "team_demo_app_identity_id" {
  description = "Used by team's Terraform to wire up the Container App. Not a secret."
  value       = azurerm_user_assigned_identity.team_demo_app.id
}
