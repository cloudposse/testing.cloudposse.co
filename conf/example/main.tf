terraform {
  required_version = ">= 0.11.2"

  backend "s3" {}
}

variable "aws_assume_role_arn" {
  type = "string"
}

provider "aws" {
  assume_role {
    role_arn = "${var.aws_assume_role_arn}"
  }
}

resource "aws_s3_bucket" "default" {
  count  = "1"
  bucket = "codefresh-gitops-example-1"
  acl    = "private"

  tags = {
    Name = "Codefresh GitOps Example"
  }
}
