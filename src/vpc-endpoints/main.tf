resource "awscc_ec2_vpc_endpoint" "this" {
  for_each = var.vpc_endpoints

  vpc_id            = var.vpc_id
  vpc_endpoint_type = each.value.type
  service_name      = length(regexall("\\.", each.value.service)) >= 2 ? each.value.service : "com.amazonaws.${local.region}.${each.value.service}"

  # Gateway endpoints
  route_table_ids = each.value.type == "Gateway" ? each.value.route_table_ids : null
  # Other endpoints
  ip_address_type     = each.value.type != "Gateway" ? each.value.ip_address_type : null
  subnet_ids          = each.value.type != "Gateway" ? each.value.subnet_ids : null
  security_group_ids  = each.value.type != "Gateway" && length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : null
  private_dns_enabled = each.value.type != "Gateway" ? each.value.private_dns_enabled : null
  service_region      = each.value.service_region
  policy_document     = each.value.policy

  tags = [
    for k, v in merge(var.common_tags, { Name = "${each.key}" }, each.value.tags) : {
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
