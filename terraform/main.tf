provider "aws" {
  region = "${var.aws_region}"
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}
