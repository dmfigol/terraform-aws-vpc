resource "awscc_ec2_vpc" "this" {
  cidr_block           = local.primary_ipv4_cidr.cidr
  ipv_4_ipam_pool_id   = local.primary_ipv4_cidr.ipam_pool_id
  ipv_4_netmask_length = local.primary_ipv4_cidr.size

  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = [
    for k, v in merge(var.common_tags, { Name = var.name }, var.vpc_tags) : {
      key   = k
      value = v
    }
  ]
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "awscc_ec2_vpc_cidr_block" "ipv4" {
  count = length(var.cidrs.ipv4) - 1

  vpc_id = awscc_ec2_vpc.this.id

  cidr_block           = var.cidrs.ipv4[count.index + 1].cidr
  ipv_4_netmask_length = var.cidrs.ipv4[count.index + 1].size
  ipv_4_ipam_pool_id   = var.cidrs.ipv4[count.index + 1].ipam_pool_id
}

resource "awscc_ec2_vpc_cidr_block" "ipv6" {
  count = length(var.cidrs.ipv6)

  vpc_id = awscc_ec2_vpc.this.id

  ipv_6_cidr_block = var.cidrs.ipv6[count.index].cidr
  ipv_6_netmask_length = (
    var.cidrs.ipv6[count.index].cidr == null &&
    var.cidrs.ipv6[count.index].ipam_pool_id == null
  ) ? null : var.cidrs.ipv6[count.index].size
  ipv_6_ipam_pool_id = var.cidrs.ipv6[count.index].ipam_pool_id
  ipv_6_cidr_block_network_border_group = (
    var.cidrs.ipv6[count.index].cidr == null &&
    var.cidrs.ipv6[count.index].ipam_pool_id == null
  ) ? local.region : null
  amazon_provided_ipv_6_cidr_block = tobool(
    var.cidrs.ipv6[count.index].cidr == null &&
    var.cidrs.ipv6[count.index].ipam_pool_id == null
  )
}

resource "awscc_ec2_internet_gateway" "this" {
  count = var.internet_gateway == null ? 0 : 1

  tags = [
    for k, v in merge(var.common_tags, { Name = "${var.name}" }, var.internet_gateway.tags) : {
      key   = k
      value = v
    }
  ]
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "awscc_ec2_vpc_gateway_attachment" "igw" {
  count = var.internet_gateway == null ? 0 : 1

  internet_gateway_id = awscc_ec2_internet_gateway.this[0].id
  vpc_id              = awscc_ec2_vpc.this.id
}

resource "awscc_ec2_vpn_gateway" "this" {
  count = var.virtual_gateway == null ? 0 : 1

  type            = "ipsec.1"
  amazon_side_asn = var.virtual_gateway.asn

  tags = [
    for k, v in merge(var.common_tags, { Name = "${var.name}" }, var.virtual_gateway.tags) : {
      key   = k
      value = v
    }
  ]
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "awscc_ec2_vpc_gateway_attachment" "vgw" {
  count = var.virtual_gateway == null ? 0 : 1

  vpn_gateway_id = awscc_ec2_vpn_gateway.this[0].id
  vpc_id         = awscc_ec2_vpc.this.id

  lifecycle {
    replace_triggered_by = [awscc_ec2_vpn_gateway.this]
  }
}

resource "awscc_ec2_egress_only_internet_gateway" "this" {
  count = var.egress_only_igw == null ? 0 : 1

  vpc_id = awscc_ec2_vpc.this.id

  tags = [
    for k, v in merge(var.common_tags, { Name = "${var.name}" }, var.egress_only_igw.tags) : {
      key   = k
      value = v
    }
  ]
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "awscc_ec2_subnet" "this" {
  for_each = local.subnets

  vpc_id               = awscc_ec2_vpc.this.id
  availability_zone_id = each.value.az_id
  cidr_block           = each.value.ipv4_cidr
  ipv_6_cidr_block     = each.value.ipv6_cidr
  ipv_6_native         = tobool(each.value.ipv4_cidr == null && each.value.ipv6_cidr != null) # if the subnet has ipv6 cidr but doesn't have ipv4 cidr
  enable_dns_64        = tobool(each.value.ipv6_cidr != null)                                 # if the subnet has ipv6 cidr, enabled dns64 always

  tags = each.value.tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "awscc_ec2_route_table" "this" {
  for_each = var.route_tables

  vpc_id = awscc_ec2_vpc.this.id

  tags = [
    for k, v in merge(var.common_tags, { Name = "${var.name}_${each.key}" }, each.value.tags) : {
      key   = k
      value = v
    }
  ]
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}


resource "awscc_ec2_subnet_route_table_association" "this" {
  for_each = {
    for subnet_name, subnet_config in local.subnets : subnet_name => subnet_config
    if subnet_config.route_table != null
  }

  subnet_id      = awscc_ec2_subnet.this[each.key].id
  route_table_id = awscc_ec2_route_table.this[each.value.route_table].id
}

resource "awscc_ec2_gateway_route_table_association" "vgw" {
  count = try(var.virtual_gateway.route_table, null) != null ? 1 : 0

  gateway_id     = awscc_ec2_vpn_gateway.this[0].id
  route_table_id = awscc_ec2_route_table.this[var.virtual_gateway.route_table].id

  depends_on = [awscc_ec2_vpc_gateway_attachment.vgw]
}

resource "awscc_ec2_gateway_route_table_association" "igw" {
  count = try(var.internet_gateway.route_table, null) != null ? 1 : 0

  gateway_id     = awscc_ec2_internet_gateway.this[0].id
  route_table_id = awscc_ec2_route_table.this[var.internet_gateway.route_table].id

  depends_on = [awscc_ec2_vpc_gateway_attachment.igw]
}

resource "awscc_ec2_route" "this" {
  for_each = {
    for route_key, route_config in flatten([
      for rt_name, rt_config in var.route_tables : [
        for route in rt_config.routes : {
          key              = "${rt_name}_${route.destination}"
          route_table_name = rt_name
          destination      = route.destination
          next_hop         = route.next_hop
        }
      ]
    ]) : route_config.key => route_config
  }

  route_table_id = awscc_ec2_route_table.this[each.value.route_table_name].id

  destination_cidr_block       = can(cidrhost(each.value.destination, 0)) && !strcontains(each.value.destination, ":") ? each.value.destination : null
  destination_ipv_6_cidr_block = can(cidrhost(each.value.destination, 0)) && strcontains(each.value.destination, ":") ? each.value.destination : null
  destination_prefix_list_id   = !can(cidrhost(each.value.destination, 0)) && startswith(each.value.destination, "pl") ? each.value.destination : null

  # Route targets based on "via" field
  gateway_id = (
    !(startswith(each.value.next_hop, "igw") || startswith(each.value.next_hop, "vgw")) ? null :
    each.value.next_hop == "igw" ? awscc_ec2_internet_gateway.this[0].id :
    each.value.next_hop == "vgw" ? awscc_ec2_vpn_gateway.this[0].id :
    each.value.next_hop # if starts with "igw" or "vgw", assumes id is put there
  )
  egress_only_internet_gateway_id = (
    !startswith(each.value.next_hop, "eigw") ? null :
    each.value.next_hop == "eigw" ? awscc_ec2_egress_only_internet_gateway.this[0].id :
    each.value.next_hop # if starts with "eigw", assumes id is put there
  )
  nat_gateway_id = (
    !startswith(each.value.next_hop, "natgw") ? null :
    startswith(each.value.next_hop, "natgw@") ? awscc_ec2_nat_gateway.this[split("@", each.value.next_hop)[1]].id :
    each.value.next_hop # assume it is natgw id
  )
  core_network_arn = (
    startswith(each.value.next_hop, "cloudwan@") ? aws_networkmanager_vpc_attachment.this[split("@", each.value.next_hop)[1]].core_network_arn :
    startswith(each.value.next_hop, "arn:aws:networkmanager:") ? each.value.next_hop :
    null
  )
  transit_gateway_id = (
    !startswith(each.value.next_hop, "tgw@") ? null :
    awscc_ec2_transit_gateway_vpc_attachment.this[split("@", each.value.next_hop)[1]].transit_gateway_id
  )
  # vpc_endpoint_id = each.value.next_hop == "vpce" ? null : null

  # local_gateway_id = each.value.next_hop == "lgw" ? null : null
  # carrier_gateway_id = each.value.next_hop == "cagw" ? null : null

  depends_on = [
    awscc_ec2_vpc_gateway_attachment.vgw,
    awscc_ec2_vpc_gateway_attachment.igw,
    awscc_ec2_transit_gateway_vpc_attachment.this,
  ] # if the routes are pointing to VGW, IGW, or TGW, wait for association to be created first
}


resource "awscc_ec2_eip" "this" {
  for_each = var.elastic_ips

  tags = [
    for k, v in merge(var.common_tags, { Name = "${var.name}_${each.key}" }, each.value.tags) : {
      key   = k
      value = v
    }
  ]
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "awscc_ec2_nat_gateway" "this" {
  for_each = var.nat_gateways

  connectivity_type = each.value.type
  subnet_id         = awscc_ec2_subnet.this[each.value.subnet].id
  allocation_id     = each.value.type == "public" ? awscc_ec2_eip.this[each.value.eips[0]].allocation_id : null
  secondary_allocation_ids = (
    each.value.type == "public" && length(each.value.eips) > 1 ?
    [for eip in slice(each.value.eips, 1, length(each.value.eips) - 1) : awscc_ec2_eip.this[eip].allocation_id] :
    null
  )

  tags = [
    for k, v in merge(var.common_tags, { Name = "${var.name}_${each.key}" }, each.value.tags) : {
      key   = k
      value = v
    }
  ]
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

module "security_groups" {
  source = "../security-groups"

  vpc_id          = awscc_ec2_vpc.this.id
  security_groups = local.resolved_security_groups
  common_tags     = var.common_tags
}

module "vpc_endpoints" {
  source = "../vpc-endpoints"

  vpc_id      = awscc_ec2_vpc.this.id
  common_tags = var.common_tags
  vpc_endpoints = { for name, endpoint in var.vpc_endpoints : name => {
    type                = endpoint.type
    service             = endpoint.service
    route_table_ids     = endpoint.type == "Gateway" ? [for rt_name in endpoint.route_tables : awscc_ec2_route_table.this[rt_name].id] : []
    subnet_ids          = endpoint.type == "Interface" ? [for subnet_name in endpoint.subnets : awscc_ec2_subnet.this[subnet_name].id] : []
    security_group_ids  = endpoint.type == "Interface" && length(endpoint.security_groups) > 0 ? [for sg_name in endpoint.security_groups : module.security_groups.security_groups[sg_name].id] : []
    policy              = endpoint.policy
    private_dns_enabled = endpoint.private_dns_enabled
    tags                = endpoint.tags
  } }
}

module "prefix_lists" {
  source = "../prefix-lists"

  common_tags  = var.common_tags
  prefix_lists = var.prefix_lists
}

resource "awscc_route53profiles_profile_association" "this" {
  count = try(var.dns.profile, null) != null ? 1 : 0

  name        = "${var.name}-route53-profile-association"
  profile_id  = var.dns.profile
  resource_id = awscc_ec2_vpc.this.id
}

resource "aws_route53_zone_association" "this" {
  for_each = try(var.dns.private_hosted_zones, null) != null ? toset(var.dns.private_hosted_zones) : []

  zone_id = data.aws_route53_zone.private_hosted_zones[each.value].id
  vpc_id  = awscc_ec2_vpc.this.id
}

# using aws provider instead of awcc because cloudwan control plane is in us-west-2
# using awscc would require separate provider definition in us-west-2
resource "aws_networkmanager_vpc_attachment" "this" {
  for_each = {
    for name, attachment in var.attachments : name => attachment
    if attachment.type == "cloudwan"
  }

  core_network_id = each.value.core_network
  vpc_arn         = "arn:aws:ec2:${local.region}:${local.account_id}:vpc/${awscc_ec2_vpc.this.vpc_id}"
  subnet_arns = [
    for subnet_name in each.value.subnets : "arn:aws:ec2:${local.region}:${local.account_id}:subnet/${awscc_ec2_subnet.this[subnet_name].subnet_id}"
  ]

  tags = merge(var.common_tags, { Name = "${var.name}_${each.key}" }, each.value.tags)
}

resource "awscc_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = {
    for name, attachment in var.attachments : name => attachment
    if attachment.type == "transit_gateway"
  }

  options = {
    dns_support                        = "enable"
    ipv_6_support                      = alltrue([for subnet_name in each.value.subnets : length(awscc_ec2_subnet.this[subnet_name].ipv_6_cidr_blocks) > 0]) ? "enable" : "disable"
    security_group_referencing_support = "enable"
    appliance_mode_support             = try(each.value.appliance_mode, false) ? "enable" : "disable"
  }

  transit_gateway_id = each.value.tgw_id
  vpc_id             = awscc_ec2_vpc.this.id
  subnet_ids = [
    for subnet_name in each.value.subnets : awscc_ec2_subnet.this[subnet_name].id
  ]

  tags = [
    for k, v in merge(var.common_tags, { Name = "${var.name}_${each.key}" }, each.value.tags) : {
      key   = k
      value = v
    }
  ]
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "awscc_ec2_transit_gateway_route_table_association" "this" {
  for_each = {
    for name, attachment in var.attachments : "${name}_${attachment.tgw_association_rt_id}" => {
      name       = name
      attachment = attachment
      rt_id      = attachment.tgw_association_rt_id
    }
    if attachment.type == "transit_gateway" && try(attachment.tgw_association_rt_id, null) != null
  }

  transit_gateway_attachment_id  = awscc_ec2_transit_gateway_vpc_attachment.this[each.value.name].id
  transit_gateway_route_table_id = each.value.rt_id
}

resource "awscc_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = {
    for attachment in flatten([
      for name, attachment in var.attachments : [
        for rt_id in attachment.tgw_propagation_rt_ids : {
          key        = "${name}_${rt_id}"
          attachment = attachment
          name       = name
          rt_id      = rt_id
        }
      ]
      if attachment.type == "transit_gateway" && length(attachment.tgw_propagation_rt_ids) > 0
    ]) : attachment.key => attachment
  }

  transit_gateway_attachment_id  = awscc_ec2_transit_gateway_vpc_attachment.this[each.value.name].id
  transit_gateway_route_table_id = each.value.rt_id
}
