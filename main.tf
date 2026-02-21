locals {
  default_resources_map = {
    for resource in var.default_resources : "default_${resource}" => {
      type = resource
    }
  }
  resources_map = merge(local.default_resources_map, var.custom_resources)
  request_body = {
    accountId   = data.aws_caller_identity.current.account_id
    region      = data.aws_region.current.id
    defaultTags = var.default_tags
    resources   = local.resources_map
  }
}

data "http" "tagops" {
  url    = var.api_url
  method = "POST"
  request_headers = {
    Content-Type   = "application/json"
    Accept         = "application/json"
    Authorization  = "Bearer ${var.api_token}"
    X-Request-Time = plantimestamp()
  }
  request_body = jsonencode(local.request_body)

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "TagOps API returned HTTP ${self.status_code}: ${self.response_body}"
    }
  }
}
