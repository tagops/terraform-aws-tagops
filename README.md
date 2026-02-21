<a href="https://tagops.cloud">
  <img src="assets/tagops-logo.png" alt="TagOps" width="200">
</a>

# TagOps Terraform Module

Terraform module that integrates with [TagOps](https://tagops.cloud) to automatically calculate and return resource tags based on your tagging rules.

The module sends your resource definitions to the TagOps API and returns the computed tags, which you can then apply to your Terraform resources.

## Requirements

| Name | Version |
|------|---------|
| [terraform](https://www.terraform.io/) | >= 1.5.0 |
| [aws](https://registry.terraform.io/providers/hashicorp/aws/latest) | >= 4.0.0 |
| [http](https://registry.terraform.io/providers/hashicorp/http/latest) | >= 3.4.0 |

## Prerequisites

- A TagOps tenant with an active API token ([Create API Token](https://tagops.cloud/documentation/admin/api-tokens.html))
- Tagging rules configured in the TagOps Console

## Security

> **Important:**  
> Do **not** use your TagOps API token as plain text in your code or variables.  
> It is **strongly recommended** to store your API token securely, such as in AWS SSM Parameter Store (as a SecureString), AWS Secrets Manager, or another secure credentials storage solution.

- The `api_token` variable is marked as `sensitive` — Terraform will not display it in plan output
- Never commit API tokens to version control

```hcl
# Example: fetch token from SSM Parameter Store
data "aws_ssm_parameter" "tagops_api_token" {
  name            = "/tagops/api_token"
  with_decryption = true
}

module "tagops" {
  source    = "tagops/tagops/aws"
  version   = "~> 1.0"
  api_token = data.aws_ssm_parameter.tagops_api_token.value
  # ...
}
```

## Usage
### Default Tags

If you are using the [default_tags feature of the AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#default_tags-configuration-block), you should also provide the same default tags to the TagOps module using the `default_tags` variable. This ensures that the tags calculated by TagOps are merged correctly with your provider-level default tags, and you have a consistent tagging strategy across your resources.

```hcl
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "my-app"
      Environment = "production"
    }
  }
}

module "tagops" {
  source    = "tagops/tagops/aws"
  version   = "~> 1.0"
  api_token = data.aws_ssm_parameter.tagops_api_token.value

  default_tags = {
    Project     = "my-app"
    Environment = "production"
  }

  # ... other configuration ...
}
```

> **Note:**  
> Make sure that the tags defined in the AWS provider's `default_tags` are also passed to the module's `default_tags` input. This avoids duplicate or missing tags and keeps your Terraform-managed tags in sync with those returned by the TagOps API.

### Default Resources

If your TagOps rules do _not_ use any resource `"name"` or specific tag key/value conditions, then all resources of the same type will receive the same block of tags. In this scenario, use `default_resources` to request default tags _per resource type_ — one API call yields tags for all your resources of that type.

Use `module.tagops.tags["default_<resource_type>"]` to apply computed tags:

```hcl
module "tagops" {
  source    = "tagops/tagops/aws"
  version   = "~> 1.0"
  api_token = data.aws_ssm_parameter.tagops_api_token.value

  default_tags = {
    managed-by       = "terraform"
    environment-name = "production"
  }

  default_resources = [
    "aws_vpc",
    "aws_subnet",
    "aws_internet_gateway",
    "aws_route_table",
    "aws_nat_gateway",
    "aws_eip",
  ]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  # ...
  vpc_tags         = merge(module.tagops.tags["default_aws_vpc"], { Name = "vpc-prod" })
  igw_tags         = merge(module.tagops.tags["default_aws_internet_gateway"], { Name = "igw-prod" })
  nat_gateway_tags = merge(module.tagops.tags["default_aws_nat_gateway"], { Name = "nat-prod" })
}
```

See the full example: [examples/default_resources](examples/default_resources)

### Custom Resources

If your TagOps rules _do_ use resource `"name"` or specific tag key/value conditions, then different resources of the same type may receive different tags. Use `custom_resources` to send each resource's details individually.

Use `module.tagops.tags["<resource_key>"]` to apply computed tags:

```hcl
module "tagops" {
  source    = "tagops/tagops/aws"
  version   = "~> 1.0"
  api_token = data.aws_ssm_parameter.tagops_api_token.value

  default_tags = {
    managed-by       = "terraform"
    environment-name = "production"
  }

  custom_resources = {
    s3_logs = {
      type = "aws_s3_bucket"
      name = "s3-bucket-for-logs-123456789012"
      tags = { app = "logs" }
    }
    s3_test = {
      type = "aws_s3_bucket"
      name = "s3-bucket-test-123456789012"
      tags = { app = "test" }
    }
  }
}

module "s3_bucket_for_logs" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket = "s3-bucket-for-logs-123456789012"
  tags   = merge({ app = "logs" }, module.tagops.tags["s3_logs"])
}
```

See the full example: [examples/custom_resources](examples/custom_resources)

### Ignore Tag Changes

Tags like `created-by` and `creation-date` are set by TagOps when the resource is first scanned. On subsequent `terraform apply` runs, Terraform would try to remove these tags. Use `lifecycle.ignore_changes` to prevent this drift:

```hcl
resource "aws_ssm_parameter" "foo" {
  name  = "foo"
  type  = "String"
  value = "bar"
  tags  = merge({ app = "test" }, module.tagops.tags["foo"])

  lifecycle {
    ignore_changes = [
      tags["created-by"],
      tags["creation-date"]
    ]
  }
}
```

See the full example: [examples/ignore_tag_changes](examples/ignore_tag_changes)

### Multi AWS Providers (Multi-Region)

When you manage resources across multiple AWS regions, create a separate TagOps module instance for each region. The module automatically detects the account ID and region from the AWS provider, so TagOps applies the correct region-specific rules to each set of resources.

Pass an aliased provider using the `providers` block:

```hcl
provider "aws" {
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  default_tags {
    tags = local.default_tags
  }
}

module "tagops" {
  source       = "tagops/tagops/aws"
  version      = "~> 1.0"
  api_token    = data.aws_ssm_parameter.tagops_api_token.value
  default_tags = local.default_tags
  custom_resources = {
    foo = {
      type = "aws_ssm_parameter"
      name = "foo"
      tags = { app = "test" }
    }
  }
}

module "tagops_us_east_1" {
  source       = "tagops/tagops/aws"
  version      = "~> 1.0"
  providers = {
    aws = aws.us-east-1
  }
  api_token    = data.aws_ssm_parameter.tagops_api_token.value
  default_tags = local.default_tags
  custom_resources = {
    foo2 = {
      type = "aws_ssm_parameter"
      name = "foo2"
      tags = { app = "test" }
    }
  }
}

resource "aws_ssm_parameter" "foo" {
  name  = "foo"
  type  = "String"
  value = "bar"
  tags  = merge({ app = "test" }, module.tagops.tags["foo"])
}

resource "aws_ssm_parameter" "foo2" {
  provider = aws.us-east-1
  name     = "foo2"
  type     = "String"
  value    = "bar2"
  tags     = merge({ app = "test" }, module.tagops_us_east_1.tags["foo2"])
}
```

See the full example: [examples/multi_aws_providers](examples/multi_aws_providers)

### Combined — Default and Custom Resources

You can use both `default_resources` and `custom_resources` together. They are merged internally:

```hcl
module "tagops" {
  source    = "tagops/tagops/aws"
  version   = "~> 1.0"
  api_token = data.aws_ssm_parameter.tagops_api_token.value

  default_tags = {
    environment = "staging"
    cost-center = "engineering"
  }

  default_resources = ["aws_s3_bucket", "aws_lambda_function"]

  custom_resources = {
    web_server = {
      type = "aws_instance"
      name = "web-staging-01"
      tags = { Name = "web-staging-01" }
    }
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `api_token` | TagOps API token for authentication | `string` | — | yes |
| `api_url` | TagOps API endpoint URL | `string` | `"https://api.tagops.cloud/terraform"` | no |
| `default_tags` | Default tags to send for tag calculation | `map(string)` | `{}` | no |
| `default_resources` | List of Terraform resource types (e.g. `["aws_vpc"]`) | `list(string)` | `[]` | no |
| `custom_resources` | Map of resources with type, name, and existing tags | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `tags` | Map of computed tags returned by the TagOps API for each resource |
| `status_code` | HTTP status code from the TagOps API |

## How It Works

1. The module collects your AWS account ID and region automatically from the AWS provider
2. Builds a request payload with your default tags, default resources, and custom resources
3. Sends a POST request to the TagOps API with your API token
4. Returns the computed tags as a map, keyed by resource identifier
5. A postcondition validates the API response — on error, the full API error message is displayed

For `default_resources`, keys are prefixed with `default_` (e.g., `default_aws_vpc`).
For `custom_resources`, keys match your map keys (e.g., `s3_logs`).

The module makes a fresh API request on every `plan`/`apply` (via `plantimestamp()` cache busting), so tag changes in your TagOps rules are reflected immediately.

## Examples

| Example | Description |
|---------|-------------|
| [default_resources](examples/default_resources) | Tag all resources from a VPC module using `default_resources` |
| [custom_resources](examples/custom_resources) | Tag specific S3 buckets with individual names and existing tags |
| [ignore_tag_changes](examples/ignore_tag_changes) | Protect dynamic tags (`created-by`, `creation-date`) from Terraform drift |
| [multi_aws_providers](examples/multi_aws_providers) | Tag resources across multiple AWS regions using aliased providers |

## Supported Resource Types

See the full list of supported Terraform resource types in the [TagOps documentation](https://tagops.cloud/documentation/reference/tagops-supported-services.html).
