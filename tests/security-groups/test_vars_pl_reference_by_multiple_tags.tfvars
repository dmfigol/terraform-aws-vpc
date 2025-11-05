vpc_id = "vpc-12345678"

common_tags = {
  Environment = "test"
  ManagedBy   = "terraform"
}

security_groups = {
  "app-sg" = {
    description = "Application security group with complex tag combinations"
    inbound = [
      {
        protocol    = "tcp"
        ports       = "443"
        source      = "pl@tag:Name=office-ips,tag:Environment=prod"
        description = "Allow HTTPS from office IP prefix list by multiple tags"
      },
      {
        protocol    = "tcp"
        ports       = "80"
        source      = "pl@tag:Name=web-services,tag:Team=frontend,tag:Env=dev"
        description = "Allow HTTP from web services with multiple tags"
      }
    ]
    outbound = [
      {
        protocol    = "tcp"
        ports       = "443"
        destination = "pl@tag:Name=aws-services,tag:Environment=shared"
        description = "Allow HTTPS to AWS services prefix list by multiple tags"
      },
      {
        protocol    = "tcp"
        ports       = "3306"
        destination = "pl@tag:Name=database,tag:Environment=prod,tag:Team=backend"
        description = "Allow MySQL to database prefix list with multiple tags"
      }
    ]
  }
}