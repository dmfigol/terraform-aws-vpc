<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_prefix_lists"></a> [prefix\_lists](#input\_prefix\_lists) | Map of prefix list names to their IDs for pl@name references | `map(string)` | `{}` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | n/a | <pre>map(object({<br/>    description = optional(string, "")<br/>    vpc_id      = optional(string, null)<br/>    inbound = optional(list(object({<br/>      protocol    = optional(string, "-1")<br/>      ports       = optional(string, null) # Format: "443,8080-8081,9000" - null means all ports<br/>      source      = string                 # Format: "10.0.0.0/8,192.168.1.0/24,2001:db8::/32,sg@sg-name,sg-xxxxx,pl@pl-name,pl-xxxxx"<br/>      description = optional(string, "")<br/>    })), [])<br/>    outbound = optional(list(object({<br/>      protocol    = optional(string, "-1")<br/>      ports       = optional(string, null) # Format: "443,8080-8081,9000" - null means all ports<br/>      destination = string                 # Format: "10.0.0.0/8,192.168.1.0/24,2001:db8::/32,sg@sg-name,sg-xxxxx,pl@pl-name,pl-xxxxx"<br/>      description = optional(string, "")<br/>    })), [])<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Default VPC id for all security groups (can be null if vpc\_id is set per security group) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_security_groups"></a> [security\_groups](#output\_security\_groups) | n/a |
| <a name="output_this"></a> [this](#output\_this) | n/a |
<!-- END_TF_DOCS -->