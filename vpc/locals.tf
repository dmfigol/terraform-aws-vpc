locals {
  account_id        = data.aws_caller_identity.current.account_id
  primary_ipv4_cidr = var.cidrs.ipv4[0]
  az_example        = data.aws_availability_zones.this.zone_ids[0]
  region            = data.aws_region.current.region
  region_prefix     = regex("^(?P<region>.*)-az\\d+$", local.az_example).region

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

}