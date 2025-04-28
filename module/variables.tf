variable "aws_region" {
  description = "The AWS region to deploy the VPC"
  type        = string
}

variable "name" {
  description = "The name of the VPC"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "vpc_tags" {
  description = "Additional tags to apply to the VPC"
  type        = map(string)
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
    az_id = any
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

