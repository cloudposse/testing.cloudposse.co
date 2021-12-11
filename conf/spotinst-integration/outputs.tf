output "api_role_arn" {
  description = "The ARN of the AWS IAM role Spotinst is allowed to assume"
  value       = join("", aws_iam_role.spot_api.*.arn)
}

output "instance_profile_name" {
  description = "Instance Profile name for worker instances launched by Spotinst"
  value       = join("", aws_iam_instance_profile.spotinst_worker.*.name)
}

output "workers_role_arn" {
  description = "Role ARN for workers in Spotinst Ocean"
  value       = join("", aws_iam_role.spotinst_worker.*.arn)
}

