common_tags = {
  Project     = "terratest"
  Environment = "test"
  ManagedBy   = "terraform"
}

prefix_lists = {
  test-max-entries-pl = {
    type = "IPv4"
    entries = [
      { cidr = "10.0.0.0/8" },
      { cidr = "172.16.0.0/12" },
      { cidr = "192.168.0.0/16" },
    ]
    max_entries_multiple = 10
  }
}