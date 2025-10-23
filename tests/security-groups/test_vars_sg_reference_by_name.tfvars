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
        source      = "sg@lb-sg"
        description = "Allow traffic from load balancer"
      }
    ]
    outbound = [
      {
        protocol    = "tcp"
        ports       = "5432"
        destination = "sg@db-sg"
        description = "Allow traffic to database"
      }
    ]
  }
  "lb-sg" = {
    description = "Load balancer security group"
    inbound = [
      {
        protocol    = "tcp"
        ports       = "443"
        source      = "0.0.0.0/0"
        description = "Allow HTTPS from anywhere"
      }
    ]
  }
  "db-sg" = {
    description = "Database security group"
    inbound = [
      {
        protocol    = "tcp"
        ports       = "5432"
        source      = "sg@app-sg"
        description = "Allow traffic from application"
      }
    ]
  }
}

prefix_lists = {}
