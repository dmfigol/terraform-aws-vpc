locals {
  account_id        = data.aws_caller_identity.current.account_id
  primary_ipv4_cidr = var.cidrs.ipv4[0]
  az_example        = data.aws_availability_zones.this.zone_ids[0]
  region            = data.aws_region.current.region
  region_prefix     = regex("^(?P<region>.*)-az[0-9]+$", local.az_example).region

  # NAT gateway configuration with expanded az_id
  # availability_mode is derived from subnet: if subnet is provided, it's zonal (null); otherwise, regional
  nat_gateways = {
    for name, natgw in var.nat_gateways : name => {
      subnet            = natgw.subnet
      type              = natgw.type
      availability_mode = natgw.subnet == null ? "regional" : null
      az_addresses = [
        for az_addr in natgw.az_addresses : {
          az_id = can(tonumber(az_addr.az_id)) ? "${local.region_prefix}-az${az_addr.az_id}" : az_addr.az_id
          eips  = az_addr.eips
        }
      ]
      eips = natgw.eips
      tags = natgw.tags
    }
  }

  # Convert pl@name references to pl@tag:Name=name for tag-based lookup
  converted_security_groups = {
    for sg_name, sg_config in var.security_groups : sg_name => {
      description = sg_config.description
      vpc_id      = try(sg_config.vpc_id, null)
      inbound = [for rule in sg_config.inbound : {
        protocol    = rule.protocol
        ports       = rule.ports
        source      = rule.source != null ? replace(rule.source, "pl@([\\w-]+)", "pl@tag:Name=$1") : null
        description = rule.description
      }]
      outbound = [for rule in sg_config.outbound : {
        protocol    = rule.protocol
        ports       = rule.ports
        destination = rule.destination != null ? replace(rule.destination, "pl@([\\w-]+)", "pl@tag:Name=$1") : null
        description = rule.description
      }]
      tags = sg_config.tags
    }
  }

  dynamic_subnets = {
    "ipv4" : [
      for i in range(length(var.cidrs.ipv4)) : [
        for subnet in var.subnets :
        { name = subnet.name, newbits = subnet.ipv4.size - (var.cidrs.ipv4[i].size != null ? var.cidrs.ipv4[i].size : split("/", var.cidrs.ipv4[i].cidr)[1]) }
        if subnet.ipv4 != null && try(subnet.ipv4.cidr, null) == null && try(subnet.ipv4.size, null) != null && try(subnet.ipv4.cidr_num, 0) == i
      ]
    ],
    "ipv6" : [
      for i in range(length(var.cidrs.ipv6)) : [
        for subnet in var.subnets :
        { name = subnet.name, newbits = subnet.ipv6.size - (var.cidrs.ipv6[i].size != null ? var.cidrs.ipv6[i].size : split("/", var.cidrs.ipv6[i].cidr)[1]) }
        if subnet.ipv6 != null && try(subnet.ipv6.cidr, null) == null && try(subnet.ipv6.size, null) != null && try(subnet.ipv6.cidr_num, 0) == i
      ]
    ],
  }
  allocated_subnet_cidrs = {
    ipv4 = merge(flatten([
      for i in range(length(var.cidrs.ipv4)) :
      zipmap(local.dynamic_subnets.ipv4[i][*].name, cidrsubnets(concat([awscc_ec2_vpc.this.cidr_block], [awscc_ec2_vpc_cidr_block.ipv4[*].cidr_block])[i], local.dynamic_subnets.ipv4[i][*].newbits...))
      if length(local.dynamic_subnets.ipv4[i]) > 0
    ])...)
    ipv6 = merge(flatten([
      for i in range(length(var.cidrs.ipv6)) :
      zipmap(local.dynamic_subnets.ipv6[i][*].name, cidrsubnets(awscc_ec2_vpc_cidr_block.ipv6[i].ipv_6_cidr_block, local.dynamic_subnets.ipv6[i][*].newbits...))
      if length(local.dynamic_subnets.ipv6[i]) > 0
    ])...)
  }

  subnets = {
    for subnet in var.subnets : subnet.name => {
      az_id       = can(tonumber(subnet.az_id)) ? "${local.region_prefix}-az${subnet.az_id}" : subnet.az_id
      ipv4_cidr   = try(subnet.ipv4.cidr, null) != null ? subnet.ipv4.cidr : try(local.allocated_subnet_cidrs.ipv4[subnet.name], null)
      ipv6_cidr   = try(subnet.ipv6.cidr, null) != null ? subnet.ipv6.cidr : try(local.allocated_subnet_cidrs.ipv6[subnet.name], null)
      route_table = subnet.route_table
      tags = [
        for k, v in merge(var.common_tags, {
          Name = "${var.name}_${subnet.name}"
          }, subnet.tags) : {
          key   = k
          value = v
        }
      ]
    }
  }

  # Resolve prefix list name references in security group rules
  resolved_security_groups = {
    for sg_name, sg_config in var.security_groups : sg_name => {
      description = sg_config.description
      vpc_id      = try(sg_config.vpc_id, null)
      tags        = sg_config.tags
      inbound = [
        for rule in sg_config.inbound : {
          protocol = rule.protocol
          ports    = rule.ports
          source = rule.source == null ? null : join(",", [
            for part in split(",", rule.source) : (
              startswith(trimspace(part), "pl@") && !startswith(trimspace(part), "pl@tag:") ?
              "pl@tag:Name=${substr(trimspace(part), 3, length(trimspace(part)) - 3)}" :
              trimspace(part)
            )
          ])
          description = rule.description
        }
      ]
      outbound = [
        for rule in sg_config.outbound : {
          protocol = rule.protocol
          ports    = rule.ports
          destination = rule.destination == null ? null : join(",", [
            for part in split(",", rule.destination) : (
              startswith(trimspace(part), "pl@") && !startswith(trimspace(part), "pl@tag:") ?
              "pl@tag:Name=${substr(trimspace(part), 3, length(trimspace(part)) - 3)}" :
              trimspace(part)
            )
          ])
          description = rule.description
        }
      ]
    }
  }

}