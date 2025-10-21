output "vpc_id" {
  value = awscc_ec2_vpc.this.id
}

output "vpc" {
  value = merge(awscc_ec2_vpc.this, { "tags" : {
    for tag in awscc_ec2_vpc.this.tags :
    tag.key => tag.value
  } })
}

output "cidrs" {
  value = {
    ipv4 = concat([awscc_ec2_vpc.this.cidr_block], awscc_ec2_vpc_cidr_block.ipv4[*].cidr_block)
    ipv6 = awscc_ec2_vpc_cidr_block.ipv6[*].ipv_6_cidr_block
  }
}

output "subnets" {
  value = {
    for k, v in awscc_ec2_subnet.this :
    k => merge(v, { "tags" : {
      for tag in v.tags :
      tag.key => tag.value
    } })
  }
}

output "route_tables" {
  value = {
    for k, v in awscc_ec2_route_table.this :
    k => merge(v, { "tags" : {
      for tag in v.tags :
      tag.key => tag.value
    } }, { "routes" : { for route_k, route_v in awscc_ec2_route.this : coalesce(route_v.destination_cidr_block, route_v.destination_ipv_6_cidr_block, route_v.destination_prefix_list_id) => coalesce(route_v.gateway_id, route_v.egress_only_internet_gateway_id, route_v.nat_gateway_id, route_v.core_network_arn, route_v.transit_gateway_id, route_v.vpc_endpoint_id, route_v.local_gateway_id, route_v.carrier_gateway_id) if route_v.route_table_id == v.id } })
  }
}

output "igw" {
  value = var.internet_gateway == null ? null : merge(awscc_ec2_internet_gateway.this[0], { "tags" : {
    for tag in awscc_ec2_internet_gateway.this[0].tags :
    tag.key => tag.value
  } })
}

output "vgw" {
  value = var.virtual_gateway == null ? null : merge(awscc_ec2_vpn_gateway.this[0], { "tags" : {
    for tag in awscc_ec2_vpn_gateway.this[0].tags :
    tag.key => tag.value
  } })
}

output "eigw" {
  value = var.egress_only_igw == null ? null : merge(awscc_ec2_egress_only_internet_gateway.this[0], { "tags" : {
    for tag in awscc_ec2_egress_only_internet_gateway.this[0].tags :
    tag.key => tag.value
  } })
}

output "elastic_ips" {
  value = {
    for k, v in awscc_ec2_eip.this :
    k => merge(v, { "tags" : {
      for tag in v.tags :
      tag.key => tag.value
    } })
  }
}

output "vpc_endpoints" {
  value = module.vpc_endpoints.this
}

output "security_groups" {
  value = module.security_groups.this
}

output "prefix_lists" {
  value = module.prefix_lists.prefix_lists
}

output "attachments" {
  value = aws_networkmanager_vpc_attachment.this
  # value = {
  #   for k, v in aws_networkmanager_vpc_attachment.this :
  #   k => merge(v, { "tags" : {
  #     for tag in v.tags :
  #     tag.key => tag.value
  #   } })
  # }
}
