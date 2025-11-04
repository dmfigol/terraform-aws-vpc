resource "aws_security_group" "this" {
  for_each = var.security_groups

  vpc_id      = coalesce(each.value.vpc_id, var.vpc_id)
  description = each.value.description
  name        = each.key

  tags = merge(var.common_tags, { Name = "${each.key}" }, each.value.tags)

}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for rule in local.security_group_rules.ingress : rule.key => rule }

  ip_protocol = each.value.protocol
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  cidr_ipv4   = each.value.cidr_ip
  cidr_ipv6   = each.value.cidr_ipv_6

  description                  = each.value.description
  security_group_id            = each.value.security_group_id
  referenced_security_group_id = each.value.source_security_group_id
  prefix_list_id               = each.value.source_prefix_list_id
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for rule in local.security_group_rules.egress : rule.key => rule }

  ip_protocol = each.value.protocol
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  cidr_ipv4   = each.value.cidr_ip
  cidr_ipv6   = each.value.cidr_ipv_6

  description                  = each.value.description
  security_group_id            = each.value.security_group_id
  referenced_security_group_id = each.value.destination_security_group_id
  prefix_list_id               = each.value.destination_prefix_list_id
}
