<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >=1.57.0, < 1.58.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | n/a | yes |
| <a name="input_prefix_lists"></a> [prefix\_lists](#input\_prefix\_lists) | Map of prefix list names to their IDs for reference resolution | `map(string)` | `{}` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | n/a | <pre>map(object({<br/>    description = optional(string, "")<br/>    inbound = optional(list(object({<br/>      protocol    = optional(string, "-1")<br/>      ports       = string                 # Format: "443,8080-8081,9000"<br/>      source      = optional(string, null) # Format: "10.0.0.0/8,192.168.1.0/24,2001:db8::/32,sg@sg-name,sg-xxxxx,pl@pl-name,pl-xxxxx"<br/>      description = optional(string, "")<br/>    })), [])<br/>    outbound = optional(list(object({<br/>      protocol    = optional(string, "-1")<br/>      ports       = string                 # Format: "443,8080-8081,9000"<br/>      destination = optional(string, null) # Format: "10.0.0.0/8,192.168.1.0/24,2001:db8::/32,sg@sg-name,sg-xxxxx,pl@pl-name,pl-xxxxx"<br/>      description = optional(string, "")<br/>    })), [])<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The name of the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_security_groups"></a> [security\_groups](#output\_security\_groups) | n/a |
| <a name="output_this"></a> [this](#output\_this) | n/a |
<!-- END_TF_DOCS -->