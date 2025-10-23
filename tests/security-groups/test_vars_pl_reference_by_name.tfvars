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
        source      = "pl@office-ips"
        description = "Allow HTTPS from office IP prefix list"
      }
    ]
    outbound = [
      {
        protocol    = "tcp"
        ports       = "443"
        destination = "pl@aws-services"
        description = "Allow HTTPS to AWS services prefix list"
      }
    ]
  }
}

prefix_lists = {
  "office-ips"   = "pl-0123456789abcdef0"
  "aws-services" = "pl-abcdef0123456789a"
}
