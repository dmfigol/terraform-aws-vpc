resource "awscc_ec2_security_group" "this" {
  for_each = var.security_groups

  vpc_id            = coalesce(each.value.vpc_id, var.vpc_id)
  group_description = each.value.description
  group_name        = each.key

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
  source_prefix_list_id    = each.value.source_prefix_list_id
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
  destination_prefix_list_id    = each.value.destination_prefix_list_id
}