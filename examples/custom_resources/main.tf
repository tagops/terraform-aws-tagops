locals {
  default_tags = {
    managed-by       = "terraform"
    environment-name = var.env
    environment-type = "non-prod"
    product          = "tagops"
  }
}

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "tagops_api_token" {
  name            = "/tagops/api_token"
  with_decryption = true
}

module "tagops" {
  source       = "./modules/tagops"
  api_token    = data.aws_ssm_parameter.tagops_api_token.value
  api_url      = var.api_url
  default_tags = local.default_tags
  custom_resources = {
    s3_logs = {
      type = "aws_s3_bucket"
      name = "s3-bucket-for-logs-${data.aws_caller_identity.current.account_id}"
      tags = {
        app     = "logs"
        product = "tagops"
      }
    }
    s3_test = {
      type = "aws_s3_bucket"
      name = "s3-bucket-test-${data.aws_caller_identity.current.account_id}"
      tags = {
        app     = "test"
        product = "tagops"
      }
    }
  }
}


module "s3_bucket_for_logs" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "s3-bucket-for-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge({
    app     = "logs"
    product = "tagops"
  }, module.tagops.tags["s3_logs"])
}

module "s3_bucket_test" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "s3-bucket-test-${data.aws_caller_identity.current.account_id}"

  tags = merge({
    app     = "test"
    product = "tagops"
  }, module.tagops.tags["s3_test"])
}