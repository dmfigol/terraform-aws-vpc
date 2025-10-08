terraform {
  source = "${get_repo_root()}//vpc"  # double slash is important to properly download nested modules
}

inputs = {
  region = "eu-central-1"
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
      # { "destination": "0.0.0.0/0", "next_hop": "igw" },
    ]},           
    "private1": {"routes": [
      # { "destination": "0.0.0.0/0", "next_hop": "natgw@natgw1" },
      { "destination": "::/0", "next_hop": "eigw" },
      { "destination": "1.2.3.4/32", "next_hop": "vgw" },
    ]},
    "private2": {"routes": [
      # { "destination": "0.0.0.0/0", "next_hop": "natgw@natgw1" },
      { "destination": "::/0", "next_hop": "eigw" },
      { "destination": "1.2.3.4/32", "next_hop": "vgw" },
    ]},     
    "ingress": {"routes": [
    ]},
  }

  elastic_ips = {
    # "natgw1_eip1": {"tags": {"EipGWTag": "EipGWValue"}},
  }

  nat_gateways = {
    # "natgw1": {"subnet": "ext1", "eips": ["natgw1_eip1"], "tags": {"NatGWTag": "NatGWValue"}},
    # "natgw-private1": {"subnet": "int1", "type": "private", "tags": {"NatGWTag": "NatGWValue"}},
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