variable "api_url" {
  description = "TagOps API endpoint URL"
  type        = string
  default     = "https://api.tagops.cloud/terraform"
}

variable "env" {
  description = "Environment"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "private_subnets_newbits" {
  description = "Private subnets newbits"
  type        = number
}

variable "public_subnets_newbits" {
  description = "Public subnets newbits"
  type        = number
}

variable "database_subnets_newbits" {
  description = "Database subnets newbits"
  type        = number
}

variable "az_number" {
  description = "Number of availability zones"
  type        = number
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Single NAT gateway"
  type        = bool
  default     = true
}
