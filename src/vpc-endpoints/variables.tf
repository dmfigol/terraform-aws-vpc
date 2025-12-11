variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_endpoints" {
  type = map(object({
    type                = string
    ip_address_type     = optional(string, "ipv4")
    service             = string
    service_region      = optional(string, null) # Interface endpoint only
    route_table_ids     = optional(list(string), [])
    subnet_ids          = optional(list(string), [])
    security_group_ids  = optional(list(string), [])
    policy              = optional(string, null)
    private_dns_enabled = optional(bool, true)
    tags                = optional(map(string), {})
  }))
  default = {}
}
