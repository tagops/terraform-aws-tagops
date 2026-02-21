locals {
  cidrs = [for cidr_block in cidrsubnets(var.cidr, var.private_subnets_newbits, var.public_subnets_newbits, var.database_subnets_newbits) : cidrsubnets(cidr_block, 1, 1)]

  default_tags = {
    managed-by       = "terraform"
    environment-name = var.env
    environment-type = "non-prod"
    product          = "tagops"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "tagops_api_token" {
  name            = "/tagops/api_token"
  with_decryption = true
}

module "tagops" {
  source       = "./modules/tagops"
  api_token    = data.aws_ssm_parameter.tagops_api_token.value
  api_url      = var.api_url
  default_tags = local.default_tags
  default_resources = [
    "aws_vpc",
    "aws_subnet",
    "aws_internet_gateway",
    "aws_route_table",
    "aws_nat_gateway",
    "aws_eip",
    "aws_network_acl",
    "aws_security_group",
  ]
}

# output "tagops_tags" {
#   value = module.tagops.tags
# }

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "6.5.1"
  name                 = var.env
  cidr                 = var.cidr
  azs                  = slice(data.aws_availability_zones.available.names, 0, var.az_number)
  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  private_subnets  = local.cidrs[0]
  public_subnets   = local.cidrs[1]
  database_subnets = local.cidrs[2]

  create_database_subnet_route_table = true

  public_subnet_tags          = merge(module.tagops.tags["default_aws_subnet"], { "kubernetes.io/cluster/eks-${var.env}" = "shared", "kubernetes.io/role/elb" = "1" })
  private_subnet_tags         = merge(module.tagops.tags["default_aws_subnet"], { "kubernetes.io/cluster/eks-${var.env}" = "shared", "kubernetes.io/role/internal-elb" = "1", "karpenter.sh/discovery" = "eks-${var.env}" })
  database_subnet_tags        = module.tagops.tags["default_aws_subnet"]
  private_subnet_names        = ["net-${var.env}-private-az1", "net-${var.env}-private-az2"]
  public_subnet_names         = ["net-${var.env}-public-az1", "net-${var.env}-public-az2"]
  database_subnet_names       = ["net-${var.env}-data-az1", "net-${var.env}-data-az2"]
  vpc_tags                    = merge(module.tagops.tags["default_aws_vpc"], { Name = "vpc-${var.env}" })
  igw_tags                    = merge(module.tagops.tags["default_aws_internet_gateway"], { Name = "igw-${var.env}" })
  public_route_table_tags     = merge(module.tagops.tags["default_aws_route_table"], { Name = "rtb-${var.env}-public" })
  private_route_table_tags    = merge(module.tagops.tags["default_aws_route_table"], { Name = "rtb-${var.env}-private" })
  database_route_table_tags   = merge(module.tagops.tags["default_aws_route_table"], { Name = "rtb-${var.env}-data" })
  nat_eip_tags                = merge(module.tagops.tags["default_aws_eip"], { Name = "eip-${var.env}-nat" })
  nat_gateway_tags            = merge(module.tagops.tags["default_aws_nat_gateway"], { Name = "nat-${var.env}-gateway" })
  default_network_acl_tags    = merge(module.tagops.tags["default_aws_network_acl"], { Name = "acl-${var.env}-default" })
  default_route_table_tags    = merge(module.tagops.tags["default_aws_route_table"], { Name = "rtb-${var.env}-default" })
  default_security_group_tags = merge(module.tagops.tags["default_aws_security_group"], { Name = "sg-${var.env}-default" })
}