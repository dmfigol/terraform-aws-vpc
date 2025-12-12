module "vpc" {
  source = "../../src//vpc"

  name = "tfexample_dev"

  cidrs = {
    "ipv4" : [
      { "cidr" : "10.20.0.0/16" }, # {"size": 24, ipam_pool_id: pool-1234}
      { "cidr" : "100.64.0.0/26" }
    ],
    "ipv6" : [
      { "size" : 56 },
      { "size" : 56 },
    ]
  }
  internet_gateway = { "tags" : { "IgwKey" : "IgwValue" } }
  virtual_gateway  = { "route_table" : "ingress", "asn" : 65000, "tags" : { "VgwKey" : "VgwValue" } }

  egress_only_igw = { "tags" : { "EigwKey" : "EigwValue" } }

  subnets = [
    { "name" : "ext1", "az_id" : 1, "ipv4" : { "size" : 24 }, "ipv6" : {}, "route_table" : "public", "tags" : { "SubnetTag" : "SubnetValue" } },
    { "name" : "ext2", "az_id" : 2, "ipv4" : { "size" : 24 }, "ipv6" : {}, "route_table" : "public" },
    { "name" : "int1", "az_id" : 1, "ipv4" : { "size" : 24 }, "ipv6" : {}, "route_table" : "private" },
    { "name" : "int2", "az_id" : 2, "ipv4" : { "size" : 24 }, "ipv6" : {}, "route_table" : "private" },
    { "name" : "ipv6only1", "az_id" : 1, "ipv6" : {}, "route_table" : "private" }, # az_id can be also provided in full form, e.g. euw2-az2. local zone id works too
    { "name" : "ipv6only2", "az_id" : 2, "ipv6" : {}, "route_table" : "private" },
    { "name" : "attach1", "az_id" : 1, "ipv4" : { "cidr" : "100.64.0.0/28" }, "ipv6" : { "cidr_num" : 1 } },
    { "name" : "attach2", "az_id" : 2, "ipv4" : { "cidr" : "100.64.0.16/28" }, "ipv6" : { "cidr_num" : 1 } },
  ]

  route_tables = {
    "public" : { "routes" : [
      { "destination" : "0.0.0.0/0", "next_hop" : "igw" },
      { "destination" : "::/0", "next_hop" : "igw" },
    ] },
    "private" : { "routes" : [
      { "destination" : "0.0.0.0/0", "next_hop" : "natgw@natgw" },
      # { "destination" : "10.0.0.0/8", "next_hop" : "cloudwan@cwan-attach" }, # or core-network arn
      { "destination" : "::/0", "next_hop" : "eigw" },
      { "destination" : "1.2.3.4/32", "next_hop" : "vgw" },
    ] },
    "ingress" : { "routes" : [
    ] },
  }

  elastic_ips = {
    # "natgw-eip1" : { "tags" : { "EipGWTag" : "EipGWValue" } },
    # "natgw-eip2" : { "tags" : { "EipGWTag" : "EipGWValue" } },
  }

  nat_gateways = {
    "natgw" : {},
    # "natgw" : { "az_addresses": [{"az_id": 1, "eips": ["natgw-eip1"]}, {"az_id": 2, "eips": ["natgw-eip2"]}], "tags" : { "NatGWTag" : "NatGWValue" } },  # control EIP assignment for regional NAT Gateway
    # "natgw1" : { "subnet" : "ext1", "eips" : ["natgw-eip1"], "tags" : { "NatGWTag" : "NatGWValue" } }, # zonal NAT gateway is supported too
    # "natgw-private-az1" : { "subnet" : "int1", "type" : "private" },  # so does private NAT Gateway
  }

  attachments = {
    # "cwan-attach" : {
    #   "type" : "cloudwan",
    #   "core_network" : "core-network-01c1c88dc7ee1101d",
    #   "subnets" : ["attach1", "attach2"],
    #   "tags" : { "Segment" : "development" }
    # },
    # "tgw-attach" : {
    #   "type" : "transit_gateway",
    #   "tgw_id" : "tgw-06ce85edb60e0427a",
    #   "subnets" : ["attach1", "attach2"],
    #   "tgw_association_rt_id" : "tgw-rtb-0785c26c8ded7bb78",
    #   "tgw_propagation_rt_ids" : ["tgw-rtb-0785c26c8ded7bb78", "tgw-rtb-0964d3e908440761c"],
    #   "appliance_mode" : true
    # }
  }

  dns = {
    # "profile" : "rp-ef9ff9cc7b9440a2",
    "private_hosted_zones" : var.private_hosted_zones,
  }

  security_groups = {
    "VPCEndpoints" : {
      "description" : "VPC endpoints",
      "inbound" : [
        { "protocol" : "tcp", "ports" : "443", "source" : "10.0.0.0/8,192.168.0.0/16", "description" : "Allow HTTPS access from multiple CIDRs" },
      ],
    },
    "Test" : {
      "description" : "Test security group",
      "inbound" : [
        { "protocol" : "tcp", "ports" : "8080-8081", "source" : "0.0.0.0/0,pl@my-pl", "description" : "Inbound access to tcp/8080 and tcp 8081" }, # pl-12345 works too
      ],
      "outbound" : [
        { "protocol" : "tcp", "ports" : "443", "destination" : "sg@VPCEndpoints", "description" : "Outbound access to VPC endpoints" },
      ],
    }
  }

  vpc_endpoints = {
    "dynamodb" : { "type" : "Gateway", "service" : "dynamodb", "route_tables" : ["public", "private"] },
    "s3" : { "type" : "Gateway", "service" : "com.amazonaws.${var.region}.s3", "route_tables" : ["public", "private"] },
    "ssm" : { "type" : "Interface", "service" : "ssm", "subnets" : ["int1", "int2"], "security_groups" : ["VPCEndpoints"] },
    # "custom" : { "type" : "Interface", "service" : "com.amazonaws.vpce.eu-west-2.vpce-svc-123456", "service_region" : "eu-west-2", "subnets" : ["int1", "int2"], "ip_address_type" : "dualstack", "security_groups" : ["VPCEndpoints"] },  # custom endpoint, also can be cross-region
  }

  prefix_lists = {
    "my-pl" : {
      "type" : "IPv4",
      "entries" : [
        { "cidr" : "2.2.2.2/32" },
        { "cidr" : "8.8.8.8/32", "description" : "Google DNS" },
        { "cidr" : "1.2.3.4/32" },
      ],
      "max_entries_multiple" : 10,
    },
    "my-ipv6-pl" : {
      "entries" : [
        { "cidr" : "2001::/48" },
        { "cidr" : "2002::/48", "description" : "Some ipv6 prefix" },
        { "cidr" : "2003::/48", "description" : "Some ipv6 prefix" },
        { "cidr" : "2004::/48", "description" : "Some ipv6 prefix" },
        { "cidr" : "2005::/48", "description" : "Some ipv6 prefix" },
      ]
    }
  }

  common_tags = merge({
    "Project" : "terraform-aws-vpc_development",
    "Environment" : "dev",
    "ManagedBy" : "terraform",
    "SourceUrl" : "https://github.com/dmfigol/terraform-aws-vpc.git",
  }, var.extra_tags)

  vpc_tags = {
    "MyVPCTag" : "MyVPCTagValue"
  }
}

provider "aws" {
  region = var.region
}

provider "awscc" {
  region = var.region
}

variable "region" {}
variable "extra_tags" {
  type    = map(string)
  default = {}
}
variable "private_hosted_zones" {
  type    = list(string)
  default = []
}
