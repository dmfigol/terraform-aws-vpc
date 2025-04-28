resource "awscc_ec2_vpc" "this" {
  cidr_block           = local.primary_ipv4_cidr.cidr
  ipv_4_ipam_pool_id   = local.primary_ipv4_cidr.ipam_pool_id
  ipv_4_netmask_length = local.primary_ipv4_cidr.size

  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = [
    for k, v in merge(var.common_tags, {
      Name = var.name
      }, var.vpc_tags) : {
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
    for k, v in merge(var.common_tags, {
      Name = "${var.name}-igw"
      }, var.internet_gateway.tags) : {
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
    for k, v in merge(var.common_tags, {
      Name = "${var.name}-vgw"
      }, var.virtual_gateway.tags) : {
      key   = k
      value = v
    }
  ]
}

resource "awscc_ec2_vpc_gateway_attachment" "vgw" {
  count = var.virtual_gateway == null ? 0 : 1

  vpn_gateway_id = awscc_ec2_vpn_gateway.this[0].id
  vpc_id         = awscc_ec2_vpc.this.id
}

resource "awscc_ec2_egress_only_internet_gateway" "this" {
  count = var.egress_only_igw == null ? 0 : 1

  vpc_id = awscc_ec2_vpc.this.id

  # tags = [
  #     for k, v in merge(var.common_tags, {
  #         Name = "${var.name}-eigw"
  #     }, var.egress_only_igw.tags) : {
  #         key   = k
  #         value = v
  #     }
  # ] 
}

resource "awscc_ec2_subnet" "this" {
  for_each = local.subnets

  vpc_id               = awscc_ec2_vpc.this.id
  availability_zone_id = each.value.az_id
  cidr_block           = each.value.ipv4_cidr
  ipv_6_cidr_block     = each.value.ipv6_cidr
  ipv_6_native         = tobool(each.value.ipv4_cidr == null && each.value.ipv6_cidr != null)
  enable_dns_64        = tobool(each.value.ipv6_cidr != null)
  tags                 = each.value.tags
}