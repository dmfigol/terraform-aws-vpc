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
        source      = "sg@nonexistent-sg"
        description = "References non-existent security group"
      }
    ]
  }
}

prefix_lists = {}
