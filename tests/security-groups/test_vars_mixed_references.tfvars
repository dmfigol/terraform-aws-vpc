vpc_id = "vpc-12345678"

common_tags = {
  Environment = "test"
  ManagedBy   = "terraform"
}

security_groups = {
  "mixed-sg" = {
    description = "Security group with mixed reference types"
    inbound = [
      {
        protocol    = "tcp"
        ports       = "8080-8081"
        source      = "10.0.0.0/8,sg@app-sg,pl@office-ips,pl-existing123"
        description = "Allow traffic from multiple sources"
      }
    ]
    outbound = [
      {
        protocol    = "tcp"
        ports       = "443,8443"
        destination = "0.0.0.0/0,sg-external123,pl-aws456"
        description = "Allow HTTPS to multiple destinations"
      }
    ]
  }
  "app-sg" = {
    description = "Referenced application security group"
    inbound     = []
  }
}

prefix_lists = {
  "office-ips" = "pl-office789"
}
