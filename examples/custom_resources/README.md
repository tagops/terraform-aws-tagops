# Custom Resources Example

This example shows how to use the TagOps module with `custom_resources` to tag specific resources by name and pass existing tags for tag calculation.

If your TagOps rules _do_ use resource `"name"` or specific tag key/value conditions, then different resources of the same type may receive different tags. In this scenario, you need to send each resource's details (name, type, existing tags) to TagOps individually using the `custom_resources` feature, so TagOps can evaluate each resource against your rules and return the correct tags.

> **Security Note:**  
> Do **not** use your TagOps API token as plain text in your code or variables.  
> It is **strongly recommended** to store your API token securely, such as in AWS SSM Parameter Store (as a SecureString), AWS Secrets Manager, or another secure credentials storage solution.  
> In the example below, the API token is fetched from SSM Parameter Store using the [AWS provider's data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter).

## How It Works

1. Define each resource in `custom_resources` with its `type`, `name`, and existing `tags`
2. TagOps calculates tags considering the resource name and existing tags against your tagging rules
3. Use `module.tagops.tags["<resource_key>"]` to apply computed tags via `merge()`

## Resources Tagged in this example

- S3 bucket for logs (`aws_s3_bucket`) — with app-specific tags
- S3 bucket for testing (`aws_s3_bucket`) — with app-specific tags
