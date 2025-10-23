vpc_id = "vpc-12345678"

common_tags = {
  Environment = "test"
  ManagedBy   = "terraform"
}

security_groups = {
  "test-sg" = {
    description = "Test security group with comma-separated ports"
    inbound = [
      {
        protocol    = "tcp"
        ports       = "443,8080,9000"
        source      = "10.0.0.0/8"
        description = "Allow multiple ports from 10.0.0.0/8"
      }
    ]
    outbound = [
      {
        protocol    = "tcp"
        ports       = "80,443,8443"
        destination = "0.0.0.0/0"
        description = "Allow multiple ports to anywhere"
      }
    ]
  }
}

prefix_lists = {}
