# Default Resources Example

This example shows how to use the TagOps module with `default_resources` to automatically tag all resources created by the [terraform-aws-modules/vpc](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) module.

If your TagOps rules do _not_ use any resource `"name"` or specific tag key/value conditions, then all resources of the same type will receive the same block of tags. In this scenario, you do **not** need to send each resource's full configuration to TagOps for evaluation.  
Instead, it's more efficient to use the `default_resources` feature to request default tags _per resource type_. This way, one API call per type yields tags for all your resources of that type.  

> **Security Note:**  
> Do **not** use your TagOps API token as plain text in your code or variables.  
> It is **strongly recommended** to store your API token securely, such as in AWS SSM Parameter Store (as a SecureString), AWS Secrets Manager, or another secure credentials storage solution.  
> In the example below, the API token is fetched from SSM Parameter Store using the [AWS provider's data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter).

## How It Works

1. Define a list of Terraform resource types in `default_resources`
2. TagOps calculates tags for each resource type based on your tagging rules
3. Use `module.tagops.tags["default_<resource_type>"]` to apply computed tags via `merge()`

## Resources Tagged in this example

- VPC (`aws_vpc`)
- Subnets (`aws_subnet`) — public, private, database
- Internet Gateway (`aws_internet_gateway`)
- Route Tables (`aws_route_table`)
- NAT Gateway (`aws_nat_gateway`)
- Elastic IP (`aws_eip`)
- Network ACL (`aws_network_acl`)
- Security Group (`aws_security_group`)
