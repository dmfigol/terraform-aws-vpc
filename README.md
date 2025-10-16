# Terraform Module for AWS Virtual Private Cloud (VPC)
> [!IMPORTANT]  
> The modules are ready for sandbox and development environments. However, they are not yet production ready - API might change until we get it right. Open an issue to suggest a new feature or change in the interface. If you want to use this in production, pin to commit and if the interface breaks, I'd recommend forking it.

The repository contains the following modules simplifying Amazon VPC deployment of ANY complexity. The main design goal is to support 98% of possible VPC functionality by extending API interface.  
Contains the following submodules:
- VPC - the main module | [schema](vpc/README.md)
- Security groups | [schema](security-groups/README.md)
- VPC endpoints | [schema](vpc-endpoints/README.md)

VPC module calls the other two modules internally, but this structure allows security groups and vpc endpoints modules to be called separately from VPC module.

### Supported features
- VPC
- IPv4/IPv6 subnets with dynamic cidr allocation
- Route tables, gateways
- Elastic IPs and NAT Gateways
- Security Groups
- VPC endpoints

Coming soon:
- DNS
- Attachments (TGW/Cloud WAN)
- Flow logs

Check [ROADMAP.md](ROADMAP.md) for more detailed information

## Usage

VPC:
```hcl
module "vpc" {
  source = "git::https://github.com/dmfigol/terraform-aws-vpc.git//src?ref=main"

  name = "tfexample_dev"

  cidrs = {
    "ipv4": [
      {"cidr": "10.10.0.0/16"},  # {"size": 24, ipam_pool_id: pool-1234}
      {"cidr": "100.64.0.0/26"} 
    ],
    "ipv6": [
      {"size": 56},
      {"size": 56},
    ]
  }
  internet_gateway = {"tags": {"IgwKey": "IgwValue"}}
  virtual_gateway = {"route_table": "ingress", "asn": 65000, "tags": {"VgwKey": "VgwValue"}}

  egress_only_igw = {"tags": {"EigwKey": "EigwValue"}}

  subnets = [
    { "name": "ext1", "az_id": 1, "ipv4": {"size": 24}, "ipv6": {}, "route_table": "public", "tags": {"SubnetTag": "SubnetValue"} },
    { "name": "ext2", "az_id": 2, "ipv4": {"size": 24}, "ipv6": {}, "route_table": "public" },
    { "name": "int1", "az_id": 1, "ipv4": {"size": 24}, "ipv6": {}, "route_table": "private1" },
    { "name": "int2", "az_id": 2, "ipv4": {"size": 24}, "ipv6": {}, "route_table": "private2" },
    { "name": "ipv6only1", "az_id": 1, "ipv6": {}, },
    { "name": "ipv6only2", "az_id": "euc1-az2", "ipv6": {} },
    { "name": "attach1", "az_id": 1, "ipv4": {"cidr": "100.64.0.0/28"}, "ipv6": {"cidr_num": 1} },
    { "name": "attach2", "az_id": 2, "ipv4": {"cidr": "100.64.0.16/28"}, "ipv6": {"cidr_num": 1} },
  ]

  route_tables = {
    "public": {"routes": [
      { "destination": "0.0.0.0/0", "next_hop": "igw" },
    ]},           
    "private1": {"routes": [
      { "destination": "0.0.0.0/0", "next_hop": "natgw@natgw1" },
      { "destination": "::/0", "next_hop": "eigw" },
      { "destination": "1.2.3.4/32", "next_hop": "vgw" },
    ]},
    "private2": {"routes": [
      { "destination": "0.0.0.0/0", "next_hop": "natgw@natgw1" },
      { "destination": "::/0", "next_hop": "eigw" },
      { "destination": "1.2.3.4/32", "next_hop": "vgw" },
    ]},     
    "ingress": {"routes": [
    ]},
  }

  elastic_ips = {
    "natgw1_eip1": {"tags": {"EipGWTag": "EipGWValue"}},
  }

  nat_gateways = {
    "natgw1": {"subnet": "ext1", "eips": ["natgw1_eip1"], "tags": {"NatGWTag": "NatGWValue"}},
    "natgw-private1": {"subnet": "int1", "type": "private", "tags": {"NatGWTag": "NatGWValue"}},
  }

  security_groups = {
    "vpc-endpoints" : {
      "description": "Security groups allowing access to VPC Endpoints",
      "inbound": [
        {"protocol": "tcp", "ports": "443", "source": "10.0.0.0/8,192.168.0.0/16", "description": "Allow HTTPS access from multiple CIDRs"},
      ],
    },
    "test" : {
      "description": "Security groups allowing access to VPC Endpoints",
      "inbound": [
        {"protocol": "tcp", "ports": "8080-8081", "source": "0.0.0.0/0", "description": "Allow inbound access on ports 8081 and 8080"},
      ],
      "outbound": [
        {"protocol": "tcp", "ports": "443", "destination": "sg@vpc-endpoints", "description": "Allow outbound access to VPC endpoints"},
      ],
    }
  }

  vpc_endpoints = {
    "dynamodb": { "type": "Gateway", "service": "dynamodb", "route_tables": ["public", "private1", "private2"] },
    "s3": { "type": "Gateway", "service": "com.amazonaws.eu-central-1.s3", "route_tables": ["public", "private1", "private2"] },
    "ssm": { "type": "Interface", "service": "ssm", "subnets": ["int1", "int2"], "security_groups": ["vpc-endpoints"] }
  }

  common_tags = {
    "Project": "terraform-aws-vpc_development",
    "Environment": "dev", 
    "ManagedBy": "terraform",
    "source_url": "https://github.com/dmfigol/terraform-aws-vpc.git"
  }
  vpc_tags = {
    "MyVPCTag": "MyVPCTagValue"
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "awscc" {
  region = "eu-central-1"
}
```

