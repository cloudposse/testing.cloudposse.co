module "api_label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.21.0"
  enabled = local.api_role_enabled

  attributes = ["api"]

  context = module.this.context
}

data "aws_ssm_parameter" "spotinst_external_id" {
  count = local.api_role_enabled ? 1 : 0
  name  = var.spotinst_external_id_ssm_key
}

locals {
  spotinst_external_id = local.api_role_enabled ? data.aws_ssm_parameter.spotinst_external_id[0].value : null
}

resource "aws_iam_role" "spot_api" {
  count = local.api_role_enabled ? 1 : 0

  name               = module.api_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.api_assume_role.*.json)
}

resource "aws_iam_role_policy_attachment" "spot_api" {
  count = local.api_role_enabled ? 1 : 0

  role       = join("", aws_iam_role.spot_api.*.name)
  policy_arn = join("", aws_iam_policy.spot_api.*.arn)
}

data "aws_iam_policy_document" "api_assume_role" {
  count = local.api_role_enabled ? 1 : 0

  statement {
    sid    = "SpotinstAWSTrustRelationship"
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${var.spotinst_aws_account_id}:root"
      ]
    }

    condition {
      test = "StringEquals"
      values = [
        local.spotinst_external_id
      ]
      variable = "sts:ExternalId"
    }
  }
}

resource "aws_iam_policy" "spot_api" {
  count = local.api_role_enabled ? 1 : 0

  name        = module.api_label.id
  description = "Spotinst permissions"

  policy = file("${path.module}/spotinst-api-standard-iam-policy.json")
}

