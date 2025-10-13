variable "vpc_id" {
  description = "The name of the VPC"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
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
