# Terraform Module for AWS Virtual Private Cloud (VPC)
> [!IMPORTANT]
> The modules are ready for sandbox and development environments. However, they are not yet production ready - API might change until we get it right. Open an issue to suggest a new feature or change in the interface. If you want to use this in production, pin to commit and if the interface breaks, I'd recommend forking it.

The repository contains the following modules simplifying Amazon VPC deployment of ANY complexity. The main design goal is to support most of possible VPC functionality by extending API interface allowing you to build VPC even with the most advanced requirements.  
Contains the following submodules:
- VPC - the main module | [reference](src/vpc/REFERENCE.md)
- Security groups | [reference](src/security-groups/REFERENCE.md)
- VPC endpoints | [reference](src/vpc-endpoints/REFERENCE.md)
- Prefix lists | [reference](src/prefix-lists/REFERENCE.md)

VPC module calls the other modules internally, but this structure allows security groups and vpc endpoints modules to be called separately from VPC module.

### Supported features
- VPC
- IPv4/IPv6 subnets with dynamic cidr allocation
- Route tables, routes (with references), gateways (IGW/VGW/EIGW)
- Elastic IPs
- NAT Gateways (zonal and regional, private and public)
- DNS profile and PHZ association
- Attachments - Cloud WAN, Transit Gateway
- Security Groups
- Prefix Lists
- VPC endpoints

Coming soon:
- Flow logs
- many others

Check [FEATURES.md](FEATURES.md) for more detailed information

## Usage

VPC:
```hcl
module "vpc" {
  source = "git::https://github.com/dmfigol/terraform-aws-vpc.git//src/vpc?ref=main"

  name = "tfexample_dev"

  cidrs = {
    "ipv4": [
      {"cidr": "10.20.0.0/16"},  # {"size": 24, "ipam_pool_id": "ipam-pool-0abc123def456789"}
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
    { "name": "int1", "az_id": 1, "ipv4": {"size": 24}, "ipv6": {}, "route_table": "private" },
    { "name": "int2", "az_id": 2, "ipv4": {"size": 24}, "ipv6": {}, "route_table": "private" },
    { "name": "ipv6only1", "az_id": 1, "ipv6": {}, "route_table": "private" },  # az_id can be also provided in full form, e.g. euw2-az2. local zone id works too
    { "name": "ipv6only2", "az_id": 2, "ipv6": {}, "route_table": "private" },
    { "name": "attach1", "az_id": 1, "ipv4": {"cidr": "100.64.0.0/28"}, "ipv6": {"cidr_num": 1} },
    { "name": "attach2", "az_id": 2, "ipv4": {"cidr": "100.64.0.16/28"}, "ipv6": {"cidr_num": 1} },
  ]

  route_tables = {
    "public": {"routes": [
      { "destination": "0.0.0.0/0", "next_hop": "igw" },
      { "destination": "::/0", "next_hop": "igw" },
    ]},
    "private": {"routes": [
      { "destination": "0.0.0.0/0", "next_hop": "natgw@natgw" },  # Regional NAT Gateway route
      { "destination": "::/0", "next_hop": "eigw" },
      { "destination": "1.2.3.4/32", "next_hop": "vgw" },
    ]},
    "ingress": {"routes": [
    ]},
  }

  elastic_ips = {
    "natgw-eip1": {"tags": {"EipTag": "EipValue"}},
    "natgw-eip2": {"tags": {"EipTag": "EipValue"}},
  }

  nat_gateways = {
    "natgw": {},  # regional NAT gateway with auto-provisioning
    # "natgw": { "az_addresses": [{"az_id": 1, "eips": ["natgw-eip1"]}, {"az_id": 2, "eips": ["natgw-eip2"]}] },  # regional with explicit EIPs per AZ
    # "natgw-zonal": { "subnet": "ext1", "eips": ["natgw-eip1"] },  # zonal NAT gateway
    # "natgw-private": { "subnet": "int1", "type": "private" },  # private NAT gateway
  }

  attachments = {
    # "cwan-attach": {
    #   "type": "cloudwan",
    #   "core_network": "core-network-0abc123def456789",
    #   "subnets": ["attach1", "attach2"],
    #   "tags": { "Segment": "development" }
    # },
    "tgw-attach": {
      "type": "transit_gateway",
      "tgw_id": "tgw-0abc123def456789",
      "subnets": ["attach1", "attach2"],
      "tgw_association_rt_id": "tgw-rtb-0abc123def456789",
      "tgw_propagation_rt_ids": ["tgw-rtb-0abc123def456789"],
      "appliance_mode": true
    }
  }

  dns = {
    "profile": "rp-0abc123def456789",
    # "private_hosted_zones": ["internal.example.com"],  # direct PHZ association is possible too
  }

  security_groups = {
    "VPCEndpoints": {
      "description": "VPC endpoints",
      "inbound": [
        {"protocol": "tcp", "ports": "443", "source": "10.0.0.0/8,192.168.0.0/16", "description": "Allow HTTPS access from multiple CIDRs"},
      ],
    },
    "Test": {
      "description": "Test security group",
      "inbound": [
        {"protocol": "tcp", "ports": "8080-8081", "source": "0.0.0.0/0,pl@my-pl", "description": "Inbound access to tcp/8080 and tcp/8081"},  # pl-12345 works too
      ],
      "outbound": [
        {"protocol": "tcp", "ports": "443", "destination": "sg@VPCEndpoints", "description": "Outbound access to VPC endpoints"},
      ],
    }
  }

  vpc_endpoints = {
    "dynamodb": { "type": "Gateway", "service": "dynamodb", "route_tables": ["public", "private"] },
    "s3": { "type": "Gateway", "service": "com.amazonaws.eu-west-2.s3", "route_tables": ["public", "private"] },
    "ssm": { "type": "Interface", "service": "ssm", "subnets": ["int1", "int2"], "security_groups": ["VPCEndpoints"] },
    # "custom": { "type": "Interface", "service": "com.amazonaws.vpce.eu-west-2.vpce-svc-0abc123def456789", "service_region": "eu-west-2", "subnets": ["int1", "int2"], "ip_address_type": "dualstack", "security_groups": ["VPCEndpoints"] },  # custom endpoint, also can be cross-region
  }

  prefix_lists = {
    "my-pl": {
      "type": "IPv4",
      "entries": [
        { "cidr": "2.2.2.2/32" },
        { "cidr": "8.8.8.8/32", "description": "Google DNS" },
      ],
      "max_entries_multiple": 10,
    },
  }

  common_tags = {
    "Project": "terraform-aws-vpc_development",
    "Environment": "dev",
    "ManagedBy": "terraform",
    "SourceUrl": "https://github.com/dmfigol/terraform-aws-vpc.git"
  }
  vpc_tags = {
    "MyVPCTag": "MyVPCTagValue"
  }
}

provider "aws" {
  region = "eu-west-2"
}

provider "awscc" {
  region = "eu-west-2"
}
```
