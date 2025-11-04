variable "vpc_id" {
  description = "Default VPC id for all security groups (can be null if vpc_id is set per security group)"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "security_groups" {
  type = map(object({
    description = optional(string, "")
    vpc_id      = optional(string, null)
    inbound = optional(list(object({
      protocol    = optional(string, "-1")
      ports       = string                 # Format: "443,8080-8081,9000"
      source      = optional(string, null) # Format: "10.0.0.0/8,192.168.1.0/24,2001:db8::/32,sg@sg-name,sg-xxxxx,pl@pl-name,pl-xxxxx"
      description = optional(string, "")
    })), [])
    outbound = optional(list(object({
      protocol    = optional(string, "-1")
      ports       = string                 # Format: "443,8080-8081,9000"
      destination = optional(string, null) # Format: "10.0.0.0/8,192.168.1.0/24,2001:db8::/32,sg@sg-name,sg-xxxxx,pl@pl-name,pl-xxxxx"
      description = optional(string, "")
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for sg_name, sg_config in var.security_groups : [
        for rule in sg_config.inbound : [
          for source in split(",", rule.source != null ? rule.source : "") : [
            for trimmed_source in [trimspace(source)] :
            # Check if sg@ reference exists in security_groups
            !startswith(trimmed_source, "sg@") ||
            can(var.security_groups[substr(trimmed_source, 3, length(trimmed_source) - 3)])
          ] if trimspace(source) != ""
        ]
      ]
    ]))
    error_message = "Security group inbound rule references a security group by name (sg@name) that does not exist in the security_groups configuration."
  }

  validation {
    condition = alltrue(flatten([
      for sg_name, sg_config in var.security_groups : [
        for rule in sg_config.outbound : [
          for destination in split(",", rule.destination != null ? rule.destination : "") : [
            for trimmed_dest in [trimspace(destination)] :
            # Check if sg@ reference exists in security_groups
            !startswith(trimmed_dest, "sg@") ||
            can(var.security_groups[substr(trimmed_dest, 3, length(trimmed_dest) - 3)])
          ] if trimspace(destination) != ""
        ]
      ]
    ]))
    error_message = "Security group outbound rule references a security group by name (sg@name) that does not exist in the security_groups configuration."
  }

}

