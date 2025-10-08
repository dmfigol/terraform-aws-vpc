output "vpc_id" {
  value = awscc_ec2_vpc.this.id
}

output "cidrs" {
  value = {
    ipv4 = concat([awscc_ec2_vpc.this.cidr_block], awscc_ec2_vpc_cidr_block.ipv4[*].cidr_block)
    ipv6 = awscc_ec2_vpc_cidr_block.ipv6[*].ipv_6_cidr_block
  }
}

output "subnets" {
  value = {
    for subnet_name, subnet in awscc_ec2_subnet.this :
    subnet_name => {
      id        = subnet.id
      az_id     = subnet.availability_zone_id
      ipv4_cidr = subnet.cidr_block
      ipv6_cidr = subnet.ipv_6_cidr_block
    }
  }
}

output "route_tables" {
  value = {
    for rt_name, rt in awscc_ec2_route_table.this :
    rt_name => {
      id     = rt.id
      routes = []
    }
  }
}

output "igw" {
  value = var.internet_gateway == null ? null : {
    "id" = awscc_ec2_internet_gateway.this[0].id
  }
}

output "vgw" {
  value = var.virtual_gateway == null ? null : {
    "id"  = awscc_ec2_vpn_gateway.this[0].id,
    "asn" = awscc_ec2_vpn_gateway.this[0].amazon_side_asn,
  }
}

output "eigw" {
  value = var.egress_only_igw == null ? null : {
    "id" = awscc_ec2_egress_only_internet_gateway.this[0].id
  }
}

output "elastic_ips" {
  value = awscc_ec2_eip.this
}

output "vpc_endpoints" {
  value = module.vpc_endpoints.vpc_endpoints
}

output "security_groups" {
  value = module.security_groups.security_groups
}