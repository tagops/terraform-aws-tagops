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
  source       = "tagops/tagops/aws"
  version      = "0.1.0"
  api_token    = data.aws_ssm_parameter.tagops_api_token.value
  api_url      = var.api_url
  default_tags = local.default_tags
  custom_resources = {
    foo = {
      type = "aws_ssm_parameter"
      name = "foo"
      tags = {
        app     = "test"
        product = "tagops"
      }
    }
  }
}

module "tagops_us_east_1" {
  source       = "tagops/tagops/aws"
  version      = "0.1.0"
  providers = {
    aws = aws.us-east-1
  }
  api_token    = data.aws_ssm_parameter.tagops_api_token.value
  api_url      = var.api_url
  default_tags = local.default_tags
  custom_resources = {
    foo2 = {
      type = "aws_ssm_parameter"
      name = "foo2"
      tags = {
        app     = "test"
        product = "tagops"
      }
    }
  }
}


resource "aws_ssm_parameter" "foo" {
  name  = "foo"
  type  = "String"
  value = "bar"
  tags = merge({
    app     = "test"
    product = "tagops"
  }, module.tagops.tags["foo"])
  lifecycle {
    ignore_changes = [
      tags["created-by"],
      tags["creation-date"]
    ]
  }
}

resource "aws_ssm_parameter" "foo2" {
  provider = aws.us-east-1
  name  = "foo2"
  type  = "String"
  value = "bar2"
  tags = merge({
    app     = "test"
    product = "tagops"
  }, module.tagops_us_east_1.tags["foo2"])
  lifecycle {
    ignore_changes = [
      tags["created-by"],
      tags["creation-date"]
    ]
  }
}