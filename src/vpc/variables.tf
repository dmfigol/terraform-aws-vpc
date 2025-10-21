variable "name" {
  description = "The name of the VPC"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags to apply to the VPC"
  type        = map(string)
  default     = {}
}

variable "cidrs" {
  description = "The CIDR blocks for the VPC"
  type = object({
    ipv4 = list(object({
      cidr         = optional(string, null)
      size         = optional(number, null)
      ipam_pool_id = optional(string, null)
    }))
    ipv6 = optional(list(object({
      cidr         = optional(string, null)
      size         = optional(number, 56)
      ipam_pool_id = optional(string, null)
    })), [])
  })
}

variable "internet_gateway" {
  description = "The internet gateway to attach to the VPC"
  type = object({
    tags        = optional(map(string), {})
    route_table = optional(string, null)
  })
  default = null
}

variable "virtual_gateway" {
  description = "The virtual gateway to attach to the VPC"
  type = object({
    asn         = optional(number, null)
    route_table = optional(string, null)
    tags        = optional(map(string), {})
  })
  default = null
}

variable "egress_only_igw" {
  description = "The egress only internet gateway to attach to the VPC"
  type = object({
    tags = optional(map(string), {})
  })
  default = null
}

variable "subnets" {
  description = "subnets to create"
  type = list(object({
    name  = string
    az_id = string
    ipv4 = optional(object({
      cidr     = optional(string)
      size     = optional(number)
      cidr_num = optional(number, 0)
    }))
    ipv6 = optional(object({
      cidr     = optional(string)
      size     = optional(number, 64)
      cidr_num = optional(number, 0)
    }))
    route_table = optional(string, null)
    tags        = optional(map(string), {})
  }))
  default = []
}

variable "route_tables" {
  type = map(object({
    routes = optional(list(object({
      destination = string
      next_hop    = string
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "elastic_ips" {
  type = map(object({
    tags = optional(map(string), {})
    # TODO: allow allocation ipam pool
  }))
  default = {}
}

variable "nat_gateways" {
  type = map(object({
    subnet = string
    type   = optional(string, "public")
    tags   = optional(map(string), {})
    eips   = optional(list(string), [])
  }))
  default = {}
}

variable "vpc_endpoints" {
  type = map(object({
    type                = string
    service             = string
    route_tables        = optional(list(string), [])
    subnets             = optional(list(string), [])
    security_groups     = optional(list(string), [])
    policy              = optional(string, null)
    private_dns_enabled = optional(bool, true)
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "dns" {
  description = "DNS configuration for Route53 profile and private hosted zones"
  type = object({
    profile              = optional(string, null)
    private_hosted_zones = optional(list(string), [])
  })
  default = null
}

variable "security_groups" {
  type = map(object({
    description = optional(string, "")
    inbound = optional(list(object({
      protocol    = optional(string, "-1")
      ports       = string                 # Format: "443,8080-8081,9000"
      source      = optional(string, null) # Format: "10.0.0.0/8,192.168.1.0/24,2001:db8::/32" or "sg-name"
      description = optional(string, "")
    })), [])
    outbound = optional(list(object({
      protocol    = optional(string, "-1")
      ports       = string                 # Format: "443,8080-8081,9000"
      destination = optional(string, null) # Format: "10.0.0.0/8,192.168.1.0/24,2001:db8::/32" or "sg-name"
      description = optional(string, "")
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "attachments" {
  type = map(object({
    type         = string
    core_network = optional(string, null)
    subnets      = list(string)
    tags         = optional(map(string), {})
  }))
  default = {}
}

variable "prefix_lists" {
  type = map(object({
    type = optional(string, null) # "IPv4" or "IPv6", defaults to "IPv4" if not provided or if no entries exist
    entries = list(object({       # List of CIDR blocks with optional descriptions
      cidr        = string
      description = optional(string, null)
    }))
    max_entries_multiple = optional(number, 1) # Multiple for max_entries calculation, defaults to 1
    tags                 = optional(map(string), {})
  }))
  default = {}
}
