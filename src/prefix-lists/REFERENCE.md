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
| <a name="input_prefix_lists"></a> [prefix\_lists](#input\_prefix\_lists) | n/a | <pre>map(object({<br/>    type = optional(string, null) # "IPv4" or "IPv6", defaults to "IPv4" if not provided or if no entries exist<br/>    entries = list(object({       # List of CIDR blocks with optional descriptions<br/>      cidr        = string<br/>      description = optional(string, null)<br/>    }))<br/>    max_entries_multiple = optional(number, 1) # Multiple for max_entries calculation, defaults to 1<br/>    tags                 = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_prefix_lists"></a> [prefix\_lists](#output\_prefix\_lists) | Map of created prefix lists |
<!-- END_TF_DOCS -->