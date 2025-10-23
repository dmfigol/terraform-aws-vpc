vpc_id = "vpc-12345678"

common_tags = {
  Environment = "test"
  ManagedBy   = "terraform"
}

security_groups = {
  "ipv6-sg" = {
    description = "Security group with IPv6 sources and destinations"
    inbound = [
      {
        protocol    = "tcp"
        ports       = "443"
        source      = "2001:db8::/32"
        description = "Allow HTTPS from IPv6 CIDR"
      },
      {
        protocol    = "tcp"
        ports       = "80"
        source      = "2001:db8:1234::/48,2001:db8:5678::/48"
        description = "Allow HTTP from multiple IPv6 CIDRs"
      }
    ]
    outbound = [
      {
        protocol    = "tcp"
        ports       = "443"
        destination = "::/0"
        description = "Allow HTTPS to any IPv6 address"
      },
      {
        protocol    = "tcp"
        ports       = "53"
        destination = "2001:4860:4860::8888/128"
        description = "Allow DNS to Google IPv6 DNS"
      }
    ]
  }
}

prefix_lists = {}
