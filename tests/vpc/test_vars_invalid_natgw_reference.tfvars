name = "test-vpc-invalid-natgw"

cidrs = {
  ipv4 = [
    { cidr = "10.0.0.0/16" }
  ]
}

common_tags = {
  Environment = "test"
  ManagedBy   = "terraform"
}

subnets = [
  { name = "public1", az_id = 1, ipv4 = { size = 24 }, route_table = "public" },
  { name = "public2", az_id = 2, ipv4 = { size = 24 }, route_table = "public" },
  { name = "private1", az_id = 1, ipv4 = { size = 24 }, route_table = "private1" },
  { name = "private2", az_id = 2, ipv4 = { size = 24 }, route_table = "private2" },
]

internet_gateway = {}

route_tables = {
  public = {
    routes = [
      { destination = "0.0.0.0/0", next_hop = "igw" }
    ]
  }
  private1 = {
    routes = [
      # This references a NAT gateway that doesn't exist
      { destination = "0.0.0.0/0", next_hop = "natgw@natgw1" }
    ]
  }
  private2 = {
    routes = [
      # This also references a NAT gateway that doesn't exist
      { destination = "0.0.0.0/0", next_hop = "natgw@natgw2" }
    ]
  }
}

# Note: No nat_gateways defined, but routes reference them
nat_gateways = {}

# Provide empty dns configuration to avoid validation errors
dns = null
