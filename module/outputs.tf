output "vpc_id" {
  value = awscc_ec2_vpc.this.id
}

output "cidrs" {
  value = {
    ipv4 = concat([awscc_ec2_vpc.this.cidr_block], [awscc_ec2_vpc_cidr_block.ipv4[*].cidr_block])
    ipv6 = concat([awscc_ec2_vpc_cidr_block.ipv6[*].ipv_6_cidr_block])
  }
}

output "subnets" {
  value = {
    for subnet_name, subnet in awscc_ec2_subnet.this :
    subnet_name => {
      az_id     = subnet.availability_zone_id
      ipv4_cidr = subnet.cidr_block
      ipv6_cidr = subnet.ipv_6_cidr_block
    }
  }
}