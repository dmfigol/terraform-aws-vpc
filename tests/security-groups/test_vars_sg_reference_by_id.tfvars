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
        ports       = "8080"
        source      = "sg-0123456789abcdef0"
        description = "Allow traffic from external security group by ID"
      }
    ]
    outbound = [
      {
        protocol    = "tcp"
        ports       = "443"
        destination = "sg-abcdef0123456789a"
        description = "Allow HTTPS to external security group by ID"
      }
    ]
  }
}

prefix_lists = {}
