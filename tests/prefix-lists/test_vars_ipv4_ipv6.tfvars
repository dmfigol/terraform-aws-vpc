common_tags = {
  Project     = "terratest"
  Environment = "test"
  ManagedBy   = "terraform"
}

prefix_lists = {
  test-ipv4-pl = {
    type = "IPv4"
    entries = [
      { cidr = "2.2.2.2/32" },
      { cidr = "8.8.8.8/32", description = "Google DNS" },
      { cidr = "1.2.3.4/32" },
    ]
    max_entries_multiple = 10
  },
  test-ipv6-pl = {
    entries = [
      { cidr = "2001::/48" },
      { cidr = "2002::/48", description = "Some ipv6 prefix" },
      { cidr = "2003::/48", description = "Some ipv6 prefix" },
      { cidr = "2004::/48", description = "Some ipv6 prefix" },
      { cidr = "2005::/48", description = "Some ipv6 prefix" },
    ]
  }
}