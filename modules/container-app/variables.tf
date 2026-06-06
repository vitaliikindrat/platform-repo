variable "name" {
  type        = string
  description = "App name. Used as container name and image name in ACR."
}

variable "resource_group_name" {
  type        = string
  description = "Team's resource group. Provisioned by the platform vending machine."
}

variable "container_app_environment_id" {
  type        = string
  description = "Platform-owned shared CAE. Look it up with a data source, don't hardcode."
}

variable "acr_login_server" {
  type        = string
  description = "Platform-owned shared ACR login server (e.g. acroidc123.azurecr.io)."
}

variable "app_identity_id" {
  type        = string
  description = "Platform-provisioned managed identity. Pre-assigned AcrPull by the vending machine."
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Image tag. The deploy workflow overwrites this — Terraform ignores it after first apply."
}

variable "initial_image" {
  type        = string
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
  description = "Public placeholder image used on first apply before the deploy workflow has pushed a real image to ACR."
}

variable "cpu" {
  type    = number
  default = 0.25
}

variable "memory" {
  type    = string
  default = "0.5Gi"
}

variable "min_replicas" {
  type    = number
  default = 0
  description = "0 = scale to zero when idle. Saves cost, adds ~3s cold start."
}

variable "max_replicas" {
  type    = number
  default = 10
}

variable "target_port" {
  type    = number
  default = 8080
}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "Plain env vars. For secrets use Key Vault references as values."
}
