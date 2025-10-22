common_tags = {
  Project     = "terratest"
  Environment = "test"
  ManagedBy   = "terraform"
}

prefix_lists = {
  test-tagged-pl = {
    type = "IPv4"
    entries = [
      { cidr = "10.0.0.0/8", description = "Private network" },
      { cidr = "172.16.0.0/12", description = "Private network" },
      { cidr = "192.168.0.0/16", description = "Private network" },
    ]
    tags = {
      CustomTag = "CustomValue"
    }
  }
}