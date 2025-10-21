<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.15.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >=1.57.0, < 1.58.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attachments"></a> [attachments](#input\_attachments) | n/a | <pre>map(object({<br/>    type         = string<br/>    core_network = optional(string, null)<br/>    subnets      = list(string)<br/>    tags         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_cidrs"></a> [cidrs](#input\_cidrs) | The CIDR blocks for the VPC | <pre>object({<br/>    ipv4 = list(object({<br/>      cidr         = optional(string, null)<br/>      size         = optional(number, null)<br/>      ipam_pool_id = optional(string, null)<br/>    }))<br/>    ipv6 = optional(list(object({<br/>      cidr         = optional(string, null)<br/>      size         = optional(number, 56)<br/>      ipam_pool_id = optional(string, null)<br/>    })), [])<br/>  })</pre> | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_dns"></a> [dns](#input\_dns) | DNS configuration for Route53 profile and private hosted zones | <pre>object({<br/>    profile              = optional(string, null)<br/>    private_hosted_zones = optional(list(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_egress_only_igw"></a> [egress\_only\_igw](#input\_egress\_only\_igw) | The egress only internet gateway to attach to the VPC | <pre>object({<br/>    tags = optional(map(string), {})<br/>  })</pre> | `null` | no |
| <a name="input_elastic_ips"></a> [elastic\_ips](#input\_elastic\_ips) | n/a | <pre>map(object({<br/>    tags = optional(map(string), {})<br/>    # TODO: allow allocation ipam pool<br/>  }))</pre> | `{}` | no |
| <a name="input_internet_gateway"></a> [internet\_gateway](#input\_internet\_gateway) | The internet gateway to attach to the VPC | <pre>object({<br/>    tags        = optional(map(string), {})<br/>    route_table = optional(string, null)<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the VPC | `string` | n/a | yes |
| <a name="input_nat_gateways"></a> [nat\_gateways](#input\_nat\_gateways) | n/a | <pre>map(object({<br/>    subnet = string<br/>    type   = optional(string, "public")<br/>    tags   = optional(map(string), {})<br/>    eips   = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_prefix_lists"></a> [prefix\_lists](#input\_prefix\_lists) | n/a | <pre>map(object({<br/>    type = optional(string, null) # "IPv4" or "IPv6", defaults to "IPv4" if not provided or if no entries exist<br/>    entries = list(object({       # List of CIDR blocks with optional descriptions<br/>      cidr        = string<br/>      description = optional(string, null)<br/>    }))<br/>    max_entries_multiple = optional(number, 1) # Multiple for max_entries calculation, defaults to 1<br/>    tags                 = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_route_tables"></a> [route\_tables](#input\_route\_tables) | n/a | <pre>map(object({<br/>    routes = optional(list(object({<br/>      destination = string<br/>      next_hop    = string<br/>    })), [])<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | n/a | <pre>map(object({<br/>    description = optional(string, "")<br/>    inbound = optional(list(object({<br/>      protocol    = optional(string, "-1")<br/>      ports       = string                 # Format: "443,8080-8081,9000"<br/>      source      = optional(string, null) # Format: "10.0.0.0/8,192.168.1.0/24,2001:db8::/32" or "sg-name"<br/>      description = optional(string, "")<br/>    })), [])<br/>    outbound = optional(list(object({<br/>      protocol    = optional(string, "-1")<br/>      ports       = string                 # Format: "443,8080-8081,9000"<br/>      destination = optional(string, null) # Format: "10.0.0.0/8,192.168.1.0/24,2001:db8::/32" or "sg-name"<br/>      description = optional(string, "")<br/>    })), [])<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | subnets to create | <pre>list(object({<br/>    name  = string<br/>    az_id = string<br/>    ipv4 = optional(object({<br/>      cidr     = optional(string)<br/>      size     = optional(number)<br/>      cidr_num = optional(number, 0)<br/>    }))<br/>    ipv6 = optional(object({<br/>      cidr     = optional(string)<br/>      size     = optional(number, 64)<br/>      cidr_num = optional(number, 0)<br/>    }))<br/>    route_table = optional(string, null)<br/>    tags        = optional(map(string), {})<br/>  }))</pre> | `[]` | no |
| <a name="input_virtual_gateway"></a> [virtual\_gateway](#input\_virtual\_gateway) | The virtual gateway to attach to the VPC | <pre>object({<br/>    asn         = optional(number, null)<br/>    route_table = optional(string, null)<br/>    tags        = optional(map(string), {})<br/>  })</pre> | `null` | no |
| <a name="input_vpc_endpoints"></a> [vpc\_endpoints](#input\_vpc\_endpoints) | n/a | <pre>map(object({<br/>    type                = string<br/>    service             = string<br/>    route_tables        = optional(list(string), [])<br/>    subnets             = optional(list(string), [])<br/>    security_groups     = optional(list(string), [])<br/>    policy              = optional(string, null)<br/>    private_dns_enabled = optional(bool, true)<br/>    tags                = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | Additional tags to apply to the VPC | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_attachments"></a> [attachments](#output\_attachments) | n/a |
| <a name="output_cidrs"></a> [cidrs](#output\_cidrs) | n/a |
| <a name="output_eigw"></a> [eigw](#output\_eigw) | n/a |
| <a name="output_elastic_ips"></a> [elastic\_ips](#output\_elastic\_ips) | n/a |
| <a name="output_igw"></a> [igw](#output\_igw) | n/a |
| <a name="output_prefix_lists"></a> [prefix\_lists](#output\_prefix\_lists) | n/a |
| <a name="output_route_tables"></a> [route\_tables](#output\_route\_tables) | n/a |
| <a name="output_security_groups"></a> [security\_groups](#output\_security\_groups) | n/a |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | n/a |
| <a name="output_vgw"></a> [vgw](#output\_vgw) | n/a |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | n/a |
| <a name="output_vpc_endpoints"></a> [vpc\_endpoints](#output\_vpc\_endpoints) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
<!-- END_TF_DOCS -->