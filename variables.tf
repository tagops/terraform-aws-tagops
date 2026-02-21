variable "api_token" {
  description = "TagOps API token for authentication. Generate from TagOps Console > Settings > API Tokens"
  type        = string
  sensitive   = true
}

variable "api_url" {
  description = "TagOps API endpoint URL"
  type        = string
  default     = "https://api.tagops.cloud/terraform"
}

variable "default_tags" {
  description = "Default tags to apply to all resources managed by TagOps rules"
  type        = map(string)
  default     = {}
}

variable "default_resources" {
  description = "List of Terraform resource types to include for tag calculation (e.g. [\"aws_vpc\", \"aws_subnet\"])"
  type        = list(string)
  default     = []
}

variable "custom_resources" {
  description = "Map of custom resources with explicit name, type, and existing tags for tag calculation"
  type = map(object({
    type = string
    name = string
    tags = optional(map(string), {})
  }))
  default = {}
}
