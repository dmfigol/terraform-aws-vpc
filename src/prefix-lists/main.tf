resource "aws_ec2_managed_prefix_list" "this" {
  for_each = var.prefix_lists

  name           = each.key
  address_family = local.prefix_list_types[each.key] == "IPv6" ? "IPv6" : "IPv4"
  max_entries    = ceil(length(each.value.entries) / each.value.max_entries_multiple) * each.value.max_entries_multiple

  dynamic "entry" {
    for_each = each.value.entries
    content {
      cidr        = entry.value.cidr
      description = entry.value.description
    }
  }

  tags = merge(var.common_tags, { Name = each.key }, each.value.tags)
}