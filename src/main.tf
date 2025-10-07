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
  ) ? var.aws_region : null
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
}

resource "awscc_ec2_route" "this" {
  for_each = {
    for route_key, route_config in flatten([
      for rt_name, rt_config in var.route_tables : [
        for route in rt_config.routes : {
          key              = "${rt_name}-${route.destination}"
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
  # core_network_arn = each.value.next_hop == "cn" ? null : null
  # transit_gateway_id = each.value.next_hop == "tgw" ? null : null
  # vpc_endpoint_id = each.value.next_hop == "vpce" ? null : null

  # local_gateway_id = each.value.next_hop == "lgw" ? null : null
  # carrier_gateway_id = each.value.next_hop == "cagw" ? null : null

  depends_on = [
    awscc_ec2_vpc_gateway_attachment.vgw,
    awscc_ec2_vpc_gateway_attachment.igw,
  ] # if the routes are pointing to VGW or IGW, wait for association to be created first
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
  count = can(var.virtual_gateway.route_table) ? 1 : 0

  gateway_id     = awscc_ec2_vpn_gateway.this[0].id
  route_table_id = awscc_ec2_route_table.this[var.virtual_gateway.route_table].id

  depends_on = [awscc_ec2_vpc_gateway_attachment.vgw]
}

resource "awscc_ec2_gateway_route_table_association" "igw" {
  count = can(var.internet_gateway.route_table) ? 1 : 0

  gateway_id     = awscc_ec2_internet_gateway.this[0].id
  route_table_id = awscc_ec2_route_table.this[var.internet_gateway.route_table].id

  depends_on = [awscc_ec2_vpc_gateway_attachment.igw]
}



resource "awscc_ec2_eip" "this" {
  for_each = var.elastic_ips

  tags = [
    for k, v in merge(var.common_tags, { Name = "${var.name}_${each.key}" }, each.value.tags) : {
      key   = k
      value = v
    }
  ]
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
}

resource "awscc_ec2_vpc_endpoint" "this" {
  for_each = var.vpc_endpoints

  vpc_id            = awscc_ec2_vpc.this.id
  service_name      = length(regexall("\\.", each.value.service)) >= 2 ? each.value.service : "com.amazonaws.${var.aws_region}.${each.value.service}"
  vpc_endpoint_type = each.value.type

  # Gateway endpoints
  route_table_ids = each.value.type == "Gateway" ? [
    for rt_name in each.value.route_tables : awscc_ec2_route_table.this[rt_name].id
  ] : null

  # Interface endpoints
  subnet_ids = each.value.type == "Interface" ? [
    for subnet_name in each.value.subnets : awscc_ec2_subnet.this[subnet_name].id
  ] : null

  security_group_ids = each.value.type == "Interface" && length(each.value.security_groups) > 0 ? [
    for sg_name in each.value.security_groups : awscc_ec2_security_group.this[sg_name].id
  ] : null

  private_dns_enabled = each.value.type == "Interface" ? each.value.private_dns_enabled : null

  tags = [
    for k, v in merge(var.common_tags, { Name = "${var.name}_${each.key}" }, each.value.tags) : {
      key   = k
      value = v
    }
  ]
}


resource "awscc_ec2_security_group" "this" {
  for_each = var.security_groups

  vpc_id            = awscc_ec2_vpc.this.id
  group_description = each.value.description
  group_name        = "${var.name}_${each.key}"

  tags = [
    for k, v in merge(var.common_tags, { Name = "${var.name}_${each.key}" }, each.value.tags) : {
      key   = k
      value = v
    }
  ]
}

resource "awscc_ec2_security_group_ingress" "this" {
  for_each = { for rule in local.security_group_rules.ingress : rule.key => rule }

  ip_protocol = each.value.protocol
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  cidr_ip     = each.value.cidr_ip
  cidr_ipv_6  = each.value.cidr_ipv_6

  description              = each.value.description
  group_id                 = each.value.security_group_id
  source_security_group_id = each.value.source_security_group_id
}

resource "awscc_ec2_security_group_egress" "this" {
  for_each = { for rule in local.security_group_rules.egress : rule.key => rule }

  ip_protocol = each.value.protocol
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  cidr_ip     = each.value.cidr_ip
  cidr_ipv_6  = each.value.cidr_ipv_6

  description                   = each.value.description
  group_id                      = each.value.security_group_id
  destination_security_group_id = each.value.destination_security_group_id
}
