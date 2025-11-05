# Test configuration for security groups with all protocols (no protocol specified)
# When no protocol is specified, it should default to -1 (all protocols) and ports should be null (all ports)

security_groups = {
  "TestAllProtocols" = {
    description = "Test security group with all protocols"
    vpc_id      = "vpc-12345678"
    outbound = [
      {
        destination = "0.0.0.0/0"
        description = "Allow all outbound traffic"
        # No protocol specified - should default to -1
        # No ports specified - should allow all ports
      }
    ]
  }
}