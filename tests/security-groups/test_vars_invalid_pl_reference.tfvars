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
        source      = "pl@nonexistent-pl"
        description = "References non-existent prefix list"
      }
    ]
  }
}

prefix_lists = {
  "office-ips" = "pl-12345"
}
