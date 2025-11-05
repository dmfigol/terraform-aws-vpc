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
        source      = "pl@tag:Name=office-ips"
        description = "Allow HTTPS from office IP prefix list by tag"
      }
    ]
    outbound = [
      {
        protocol    = "tcp"
        ports       = "443"
        destination = "pl@tag:Name=aws-services"
        description = "Allow HTTPS to AWS services prefix list by tag"
      }
    ]
  }
}