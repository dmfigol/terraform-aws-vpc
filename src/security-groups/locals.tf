locals {
  # Parse port string format "443,8080-8081,9000" into individual port rules
  ingress_port_specs = flatten([
    for sg_name, sg_config in var.security_groups : [
      for rule in sg_config.inbound : [
        for port_part in split(",", rule.ports) : {
          sg_name    = sg_name
          rule       = rule
          port_part  = trimspace(port_part)
          from_port  = strcontains(port_part, "-") ? tonumber(split("-", port_part)[0]) : tonumber(port_part)
          to_port    = strcontains(port_part, "-") ? tonumber(split("-", port_part)[1]) : tonumber(port_part)
          key_suffix = strcontains(port_part, "-") ? "${split("-", port_part)[0]}-${split("-", port_part)[1]}" : port_part
        }
      ]
    ]
  ])

  # Parse port string format "443,8080-8081,9000" into individual port rules for egress
  egress_port_specs = flatten([
    for sg_name, sg_config in var.security_groups : [
      for rule in sg_config.outbound : [
        for port_part in split(",", rule.ports) : {
          sg_name    = sg_name
          rule       = rule
          port_part  = trimspace(port_part)
          from_port  = strcontains(port_part, "-") ? tonumber(split("-", port_part)[0]) : tonumber(port_part)
          to_port    = strcontains(port_part, "-") ? tonumber(split("-", port_part)[1]) : tonumber(port_part)
          key_suffix = strcontains(port_part, "-") ? "${split("-", port_part)[0]}-${split("-", port_part)[1]}" : port_part
        }
      ]
    ]
  ])

  # Create individual CIDR entries for ingress
  ingress_cidr_specs = flatten([
    for port_spec in local.ingress_port_specs : [
      for cidr_part in split(",", port_spec.rule.source != null ? port_spec.rule.source : "") : [
        for trimmed_cidr in [trimspace(cidr_part)] : [
          for parsed_ref in [{
            original    = trimmed_cidr
            sg_name_ref = startswith(trimmed_cidr, "sg@") ? substr(trimmed_cidr, 3, length(trimmed_cidr) - 3) : trimmed_cidr
            pl_name_ref = startswith(trimmed_cidr, "pl@") ? substr(trimmed_cidr, 3, length(trimmed_cidr) - 3) : trimmed_cidr
            is_ipv6     = can(cidrhost(trimmed_cidr, 0)) && strcontains(trimmed_cidr, ":")
            is_ipv4     = can(cidrhost(trimmed_cidr, 0)) && !strcontains(trimmed_cidr, ":")
            is_sg       = startswith(trimmed_cidr, "sg@") || (startswith(trimmed_cidr, "sg-") && !can(cidrhost(trimmed_cidr, 0)))
            is_pl       = startswith(trimmed_cidr, "pl@") || (startswith(trimmed_cidr, "pl-") && !can(cidrhost(trimmed_cidr, 0)))
            }] : [
            {
              sg_name     = port_spec.sg_name
              rule        = port_spec.rule
              port_spec   = port_spec
              cidr        = trimmed_cidr
              sg_name_ref = parsed_ref.sg_name_ref
              pl_name_ref = parsed_ref.pl_name_ref
              is_ipv6     = parsed_ref.is_ipv6
              is_ipv4     = parsed_ref.is_ipv4
              is_sg       = parsed_ref.is_sg
              is_pl       = parsed_ref.is_pl
            }
          ] if trimmed_cidr != ""
        ]
      ]
    ]
  ])

  # Create individual CIDR entries for egress
  egress_cidr_specs = flatten([
    for port_spec in local.egress_port_specs : [
      for cidr_part in split(",", port_spec.rule.destination != null ? port_spec.rule.destination : "") : [
        for trimmed_cidr in [trimspace(cidr_part)] : [
          for parsed_ref in [{
            original    = trimmed_cidr
            sg_name_ref = startswith(trimmed_cidr, "sg@") ? substr(trimmed_cidr, 3, length(trimmed_cidr) - 3) : trimmed_cidr
            pl_name_ref = startswith(trimmed_cidr, "pl@") ? substr(trimmed_cidr, 3, length(trimmed_cidr) - 3) : trimmed_cidr
            is_ipv6     = can(cidrhost(trimmed_cidr, 0)) && strcontains(trimmed_cidr, ":")
            is_ipv4     = can(cidrhost(trimmed_cidr, 0)) && !strcontains(trimmed_cidr, ":")
            is_sg       = startswith(trimmed_cidr, "sg@") || (startswith(trimmed_cidr, "sg-") && !can(cidrhost(trimmed_cidr, 0)))
            is_pl       = startswith(trimmed_cidr, "pl@") || (startswith(trimmed_cidr, "pl-") && !can(cidrhost(trimmed_cidr, 0)))
            }] : [
            {
              sg_name     = port_spec.sg_name
              rule        = port_spec.rule
              port_spec   = port_spec
              cidr        = trimmed_cidr
              sg_name_ref = parsed_ref.sg_name_ref
              pl_name_ref = parsed_ref.pl_name_ref
              is_ipv6     = parsed_ref.is_ipv6
              is_ipv4     = parsed_ref.is_ipv4
              is_sg       = parsed_ref.is_sg
              is_pl       = parsed_ref.is_pl
            }
          ] if trimmed_cidr != ""
        ]
      ]
    ]
  ])

  # Build final security group rules for ingress
  security_group_rules_ingress = [
    for cidr_spec in local.ingress_cidr_specs : {
      key                      = "${cidr_spec.sg_name}_${cidr_spec.rule.protocol}_${cidr_spec.port_spec.key_suffix}_${cidr_spec.cidr}"
      security_group_id        = awscc_ec2_security_group.this[cidr_spec.sg_name].id
      protocol                 = cidr_spec.rule.protocol
      from_port                = cidr_spec.port_spec.from_port
      to_port                  = cidr_spec.port_spec.to_port
      cidr_ip                  = cidr_spec.is_ipv4 ? cidr_spec.sg_name_ref : null
      cidr_ipv_6               = cidr_spec.is_ipv6 ? cidr_spec.sg_name_ref : null
      source_security_group_id = cidr_spec.is_sg ? (can(awscc_ec2_security_group.this[cidr_spec.sg_name_ref].id) ? awscc_ec2_security_group.this[cidr_spec.sg_name_ref].id : cidr_spec.sg_name_ref) : null
      source_prefix_list_id = cidr_spec.is_pl ? (
        startswith(cidr_spec.cidr, "pl@") ?
        try(var.prefix_lists[cidr_spec.pl_name_ref], null) :
        cidr_spec.pl_name_ref
      ) : null
      description = cidr_spec.rule.description
    }
  ]

  # Build final security group rules for egress
  security_group_rules_egress = [
    for cidr_spec in local.egress_cidr_specs : {
      key                           = "${cidr_spec.sg_name}_${cidr_spec.rule.protocol}_${cidr_spec.port_spec.key_suffix}_${cidr_spec.cidr}"
      security_group_id             = awscc_ec2_security_group.this[cidr_spec.sg_name].id
      protocol                      = cidr_spec.rule.protocol
      from_port                     = cidr_spec.port_spec.from_port
      to_port                       = cidr_spec.port_spec.to_port
      cidr_ip                       = cidr_spec.is_ipv4 ? cidr_spec.sg_name_ref : null
      cidr_ipv_6                    = cidr_spec.is_ipv6 ? cidr_spec.sg_name_ref : null
      destination_security_group_id = cidr_spec.is_sg ? (can(awscc_ec2_security_group.this[cidr_spec.sg_name_ref].id) ? awscc_ec2_security_group.this[cidr_spec.sg_name_ref].id : cidr_spec.sg_name_ref) : null
      destination_prefix_list_id = cidr_spec.is_pl ? (
        startswith(cidr_spec.cidr, "pl@") ?
        try(var.prefix_lists[cidr_spec.pl_name_ref], null) :
        cidr_spec.pl_name_ref
      ) : null
      description = cidr_spec.rule.description
    }
  ]

  security_group_rules = {
    ingress = local.security_group_rules_ingress
    egress  = local.security_group_rules_egress
  }

}