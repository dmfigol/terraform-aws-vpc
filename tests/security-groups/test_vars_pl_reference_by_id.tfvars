vpc_id = "vpc-12345678"

common_tags = {
  Environment = "test"
  ManagedBy   = "terraform"
}

security_groups = {
  "app-sg" = {
    description = "Application security group"
    inbound = [
      {
        protocol    = "tcp"
        ports       = "443"
        source      = "pl-0123456789abcdef0"
        description = "Allow HTTPS from prefix list by ID"
      }
    ]
    outbound = [
      {
        protocol    = "tcp"
        ports       = "443"
        destination = "pl-fedcba9876543210f"
        description = "Allow HTTPS to prefix list by ID"
      }
    ]
  }
}

prefix_lists = {}
