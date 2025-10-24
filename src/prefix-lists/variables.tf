variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
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
