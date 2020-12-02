
variable "region" {
  type        = string
  description = "AWS Region"
}

// Spotinst configuration
variable "spotinst_token_ssm_key" {
  type        = string
  description = "SSM key for Spot Personal Access token"
  default     = "/spotinst/access_token"
}

variable "spotinst_account_ssm_key" {
  type        = string
  description = "SSM key for Spot account ID"
  default     = "/spotinst/account_id"
}

variable "spotinst_external_id_ssm_key" {
  type        = string
  description = "SSM key for Spot AWS integration External ID"
  default     = "/spotinst/external_id"
}

variable "spotinst_aws_account_id" {
  type        = string
  description = "Spotinst AWS account ID for assuming role in your account"
  default     = "922761411349"
}

variable "create_api_iam_role" {
  type        = bool
  description = "Set true to create an IAM Role for Spotinst to connect to your AWS account"
  default     = true
}

variable "create_instance_profile" {
  type        = bool
  description = "Set true to create an AWS Instance Profile to use for Spotinst Worker instances."
  default     = true
}

variable "workers_role_additional_policy_arns" {
  type        = list(string)
  default     = []
  description = "List of policy ARNs that will be attached to the workers default role on creation in addition to the defaults"
}
