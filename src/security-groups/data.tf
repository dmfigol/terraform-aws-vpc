# Data source to lookup prefix lists by tags
data "aws_ec2_managed_prefix_list" "by_tags" {
  for_each = local.tag_based_prefix_list_refs

  dynamic "filter" {
    for_each = each.value.tag_filters
    content {
      name   = filter.key
      values = [filter.value]
    }
  }
}

# Data source to lookup prefix lists by ID (for existing pl- references)
data "aws_ec2_managed_prefix_list" "by_id" {
  for_each = local.id_based_prefix_list_refs

  filter {
    name   = "prefix-list-id"
    values = [each.value.prefix_list_id]
  }
}