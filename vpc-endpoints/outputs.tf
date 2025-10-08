output "vpc_endpoints" {
  value = {
    for name, endpoint in awscc_ec2_vpc_endpoint.this :
    name => {
      id                  = endpoint.id
      type                = endpoint.vpc_endpoint_type
      service_name        = endpoint.service_name
      vpc_id              = endpoint.vpc_id
      subnet_ids          = endpoint.subnet_ids
      security_group_ids  = endpoint.security_group_ids
      route_table_ids     = endpoint.route_table_ids
      private_dns_enabled = endpoint.private_dns_enabled
    }
  }
}