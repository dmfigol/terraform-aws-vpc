# Terraform Module for AWS Virtual Private Cloud (VPC)
Terraform module for AWS VPC supporting VPC deployment of ANY complexity. 


## Features
- [x] IPv4 and IPv6 CIDR blocks (one or more), static or from IPAM
- [x] Subnets
  - IPv4/IPv6/dual-stack
  - CIDRs can be statically or dynamically allocated
  - Subnets can be in AZs, local or wavelength zones 
- [ ] Route tables, routes supporting object references, e.g. @igw, @tgw, @cwan, @nat-gw:nat-az1
- [ ] NAT gateway
- [ ] Elastic IPs
- [ ] Internet gateway, Virtual gateway with ingress routing, Egress only IGW
- [ ] Attachments: transit gateway, cloudwan
- [ ] DNS: Route53 profile association, VPC Authorization/Association, Resolver Rules Association, Query logs, 
- [ ] Endpoints:
  - gateway
  - interface
  - resource
  - service network (VPC lattice)
  - gateway load balancer endpoint
- [ ] VPC lattice service network association
- [ ] Security groups
- [ ] VPC flow logs
  - CloudWatch
  - S3
  - Data Firehose
- [ ] AWS Network Firewall
- [ ] VPC Route Server
- [ ] VPC Block Public Access
- [ ] Network Access lists
- [ ] VGW-DXGW association
- [ ] Site-to-Site VPN

## Usage

TF Module instantiation
```
module "vpc" {
  source = "github.com/dmfigol/terraform-aws-vpc//src?ref=main"

  name = var.name
  aws_region = var.aws_region
  cidrs = var.cidrs
  internet_gateway = var.internet_gateway
  virtual_gateway = var.virtual_gateway
  egress_only_igw = var.egress_only_igw
  subnets = var.subnets
  route_tables = var.route_tables
  common_tags = var.common_tags
  vpc_tags = var.vpc_tags
}
```

TF vars example:
```hcl
aws_region = "eu-central-1"
name = "unicorn-tf-app_dev"

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
virtual_gateway = {"tags": {"VgwKey": "VgwValue"}}
egress_only_igw = {"tags": {"EigwKey": "EigwValue"}}

subnets = [
    { "name": "int-az1", "az_id": "euc1-az1", "ipv4": {"size": 24}, "ipv6": {}, "route_table": "internal", "tags": {"SubnetTag": "SubnetValue"} },
    { "name": "int-az2", "az_id": "euc1-az2", "ipv4": {"size": 24}, "ipv6": {}, "route_table": "internal" },
    { "name": "ipv6only-az1", "az_id": "euc1-az1", "ipv6": {} },
    { "name": "ipv6only-az2", "az_id": "euc1-az2", "ipv6": {} },
    { "name": "attach-az1", "az_id": "euc1-az1", "ipv4": {"cidr": "100.64.0.0/28"}, "ipv6": {"cidr_num": 1} },
    { "name": "attach-az2", "az_id": "euc1-az2", "ipv4": {"cidr": "100.64.0.16/28"}, "ipv6": {"cidr_num": 1} },
]

route_tables = {
    "internal": {"routes": [
        {"route": "0.0.0.0/0", "via": "@igw"},
        {"route": "::/0", "via": "@eigw"},
        {"route": "1.2.3.4/32", "via": "@vgw"},
    ]}
}

common_tags = {
    "Project": "unicorn-tf-app",
    "Environment": "dev", 
    "ManagedBy": "terraform",
}
vpc_tags = {
    "MyVPCTag": "MyVPCTagValue"
}
```

Terragrunt example: examples/terragrunt.hcl

### Extending VPC with more CIDRs
