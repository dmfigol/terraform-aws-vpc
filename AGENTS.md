# Terraform AWS VPC Module - Agent Guidelines
For any change validate it with plan using
`cd examples && terragrunt validate && terragrunt plan`
make sure that the exit code is 0

## Build/Lint/Test Commands
```bash
```

## Code Style Guidelines
- Use `awscc_` provider resources (AWS Cloud Control API). Use `aws` provider ONLY for data resources.
- Resource naming: `this` for single resources, plural for collections (e.g., `awscc_ec2_vpc.this`, `awscc_ec2_subnet.this`)
- Variable names: snake_case, descriptive and consistent with AWS terminology
- Tags: Merge `common_tags` with resource-specific tags using `merge()` function
- Use `for_each` for multiple resources, `count` for conditional single resources
- Local values in `locals.tf` for complex calculations and data transformations
- CIDR handling: Support both static CIDRs and IPAM pool allocations
- IPv6 support: Enable DNS64 for IPv6 subnets, handle native IPv6 subnets
- Resource references: Use `igw`, `vgw`, `eigw` syntax for gateway references in route tables