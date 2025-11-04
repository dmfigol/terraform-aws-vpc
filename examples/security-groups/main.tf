module "vpc" {
  source = "../../src/security-groups"

  vpc_id = null

  security_groups = {
    "vpc-endpoints" : {
      "description" : "Security groups allowing access to VPC Endpoints",
      "vpc_id" : "vpc-123456",
      "inbound" : [
        { "protocol" : "tcp", "ports" : "443", "source" : "10.0.0.0/8,192.168.0.0/16", "description" : "Allow HTTPS access from multiple CIDRs" },
      ],
    },
    "test" : {
      "description" : "Security groups allowing access to VPC Endpoints",
      "vpc_id" : "vpc-456321",
      "inbound" : [
        { "protocol" : "tcp", "ports" : "8080-8081", "source" : "0.0.0.0/0,pl-0946074271599680d", "description" : "Allow inbound access on ports 8081 and 8080" },
      ],
      "outbound" : [
        { "protocol" : "tcp", "ports" : "443", "destination" : "sg@vpc-endpoints", "description" : "Allow outbound access to VPC endpoints" },
      ],
    }
  }

}
