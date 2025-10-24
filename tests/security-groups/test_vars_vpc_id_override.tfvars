vpc_id = null

security_groups = {
  "vpc1-sg" = {
    description = "Security group in VPC 1"
    vpc_id      = "vpc-111111"
    inbound = [
      { protocol = "tcp", ports = "443", source = "10.0.0.0/8", description = "Allow HTTPS from 10.0.0.0/8" }
    ]
  }
  "vpc2-sg" = {
    description = "Security group in VPC 2"
    vpc_id      = "vpc-222222"
    inbound = [
      { protocol = "tcp", ports = "22", source = "192.168.0.0/16", description = "Allow SSH from 192.168.0.0/16" }
    ]
  }
}
