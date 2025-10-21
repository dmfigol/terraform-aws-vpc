locals {
  # Determine the type for each prefix list
  prefix_list_types = {
    for name, pl in var.prefix_lists : name => (
      pl.type != null ? pl.type : (
        length(pl.entries) > 0 && can(cidrhost(pl.entries[0].cidr, 0)) && strcontains(pl.entries[0].cidr, ":") ? "IPv6" : "IPv4"
      )
    )
  }
}