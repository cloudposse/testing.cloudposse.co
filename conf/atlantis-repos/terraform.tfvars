terragrunt = {
  terraform {
    source = "git::https://github.com/cloudposse/terraform-github-repository-webhooks.git//?ref=tags/0.1.0"

    extra_arguments "retry_lock" {
      commands = [
        "apply",
        "destroy",
        "plan",
      ]

      arguments = [
        "-lock-timeout=1m", 
        "-no-color", 
        "-input=false"
      ]

      env_vars = {
        TF_VAR_github_token   = "${get_env("GITHUB_TOKEN", "")}"
        TF_VAR_webhook_secret = "${get_env("ATLANTIS_GH_WEBHOOK_SECRET", "")}"
      }
    }
  }

  remote_state {
    backend = "s3"

    config {
      bucket         = "${get_env("TF_BUCKET", "")}"
      key            = "${path_relative_to_include()}/${get_env("TF_FILE", "terraform.tfstate")}"
      region         = "${get_env("TF_BUCKET_REGION", "us-east-1")}"
      encrypt        = true
      dynamodb_table = "${get_env("TF_DYNAMODB_TABLE", "")}"
    }
  }
}

webhook_url = "https://atlantis.testing.cloudposse.co/events"
webhook_active = true

github_organization = "cloudposse"

github_repositories = ["testing.cloudposse.co", "alpinist"]

events = ["pull_request_review_comment", "pull_request", "pull_request_review", "issue_comment", "push"]

name = "web"
