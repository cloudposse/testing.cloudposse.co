locals {
  aws_policy_prefix = "arn:aws:iam::aws:policy"
}

data "aws_iam_policy_document" "spotinst_worker_assume_role" {
  count = local.instance_profile_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

module "spotinst_worker_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled = local.instance_profile_enabled

  attributes = ["worker"]

  context = module.this.context
}

resource "aws_iam_instance_profile" "spotinst_worker" {
  count = local.instance_profile_enabled ? 1 : 0
  name  = module.spotinst_worker_label.id
  role  = join("", aws_iam_role.spotinst_worker.*.name)
}

resource "aws_iam_role" "spotinst_worker" {
  count              = local.instance_profile_enabled ? 1 : 0
  name               = module.spotinst_worker_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.spotinst_worker_assume_role.*.json)
  tags               = module.spotinst_worker_label.tags
}

resource "aws_iam_role_policy_attachment" "spotinst_amazon_eks_worker_node_policy" {
  count      = local.instance_profile_enabled ? 1 : 0
  policy_arn = format("%s/%s", local.aws_policy_prefix, "AmazonEKSWorkerNodePolicy")
  role       = join("", aws_iam_role.spotinst_worker.*.name)
}

resource "aws_iam_role_policy_attachment" "spotinst_amazon_eks_cni_policy" {
  count      = local.instance_profile_enabled ? 1 : 0
  policy_arn = format("%s/%s", local.aws_policy_prefix, "AmazonEKS_CNI_Policy")
  role       = join("", aws_iam_role.spotinst_worker.*.name)
}

resource "aws_iam_role_policy_attachment" "spotinst_amazon_ec2_container_registry_read_only" {
  count      = local.instance_profile_enabled ? 1 : 0
  policy_arn = format("%s/%s", local.aws_policy_prefix, "AmazonEC2ContainerRegistryReadOnly")
  role       = join("", aws_iam_role.spotinst_worker.*.name)
}

resource "aws_iam_role_policy_attachment" "existing_policies_attach_to_workers_role" {
  count      = local.instance_profile_enabled ? length(var.workers_role_additional_policy_arns) : 0
  policy_arn = var.workers_role_additional_policy_arns[count.index]
  role       = join("", aws_iam_role.spotinst_worker.*.name)
}

