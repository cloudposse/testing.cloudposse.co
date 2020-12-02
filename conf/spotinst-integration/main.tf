locals {
  enabled                  = module.this.enabled
  instance_profile_enabled = local.enabled && var.create_instance_profile
  api_role_enabled         = local.enabled && var.create_api_iam_role
}
