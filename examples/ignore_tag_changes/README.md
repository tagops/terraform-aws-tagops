# Ignore Tag Changes Example

This example shows how to use the TagOps module with `lifecycle.ignore_changes` to prevent Terraform from overwriting dynamic tags that are managed outside of Terraform (e.g., `created-by` and `creation-date`).

Tags like `created-by` and `creation-date` are set by TagOps when the resource is first scanned. On subsequent `terraform apply` runs, Terraform would try to remove these tags (since they're not in the Terraform config). Using `ignore_changes` prevents this drift.

> **Security Note:**  
> Do **not** use your TagOps API token as plain text in your code or variables.  
> It is **strongly recommended** to store your API token securely, such as in AWS SSM Parameter Store (as a SecureString), AWS Secrets Manager, or another secure credentials storage solution.  
> In the example below, the API token is fetched from SSM Parameter Store using the [AWS provider's data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter).

## How It Works

1. Define resources in `custom_resources` with their `type`, `name`, and existing `tags`
2. Apply computed tags from TagOps via `merge()`
3. Add `lifecycle { ignore_changes }` for tags that are set dynamically by TagOps after resource creation

```hcl
lifecycle {
  ignore_changes = [
    tags["created-by"],
    tags["creation-date"]
  ]
}
```

## Resources Tagged in this example

- SSM Parameters (`aws_ssm_parameter`) — with dynamic tag protection
