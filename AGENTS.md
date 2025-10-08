# Terraform AWS VPC Module - Agent Guidelines
The project is using Terragrunt with OpenTofu.  
For any change validate it using `task check-llm` command that is optimized for machines.  
If you change any file inside src/ directory, run also `tofu fmt -recursive`

## Build/Lint/Test Commands
Lint
```bash
tofu fmt -recursive
```

## Code Style Guidelines
- Use `awscc_` provider resources (AWS Cloud Control API). Use `aws` provider ONLY for data resources.
- Resource naming: `this` for single resources, plural for collections (e.g., `awscc_ec2_vpc.this`, `awscc_ec2_subnet.this`)
- Variable names: snake_case, descriptive and consistent with AWS terminology
- Do NOT modify variables.tf unless explicitly asked
- Tags: Merge `common_tags` with resource-specific tags using `merge()` function
- Use `for_each` for multiple resources, `count` for conditional single resources
- Create local variables in `locals.tf` for complex calculations and data transformations
- Resource references: Use `igw`, `vgw`, `eigw` and `natgw@<name>` syntax for references in route tables