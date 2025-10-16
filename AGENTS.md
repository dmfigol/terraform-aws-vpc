# Terraform - Agent Guidelines
- The project is using Terragrunt with OpenTofu for tests.  
- For any change validate it using `task check-llm` command inside the appropriate terragrunt folder.
- Verify that resources specified in input terragrunt.hcl are visible in the plan.  
- At the end, run `task fmt` to automatically format modules.

## Code Style Guidelines
- Prefer creating resources with awscc_ provider (AWS Cloud Control API). Use aws provider for data resources only.
- Resource naming: this for single resources, plural for collections (e.g., awscc_ec2_vpc.this, awscc_ec2_subnet.this).
- Variable names: snake_case, descriptive and consistent with AWS terminology.
- Avoid modifying terragrunt.hcl unless explicitly asked.
- Tags: merge common_tags with resource-specific tags using merge() function.
- Use for_each for multiple resources, count for conditional single resources.
- Create local variables in locals.tf for complex calculations and data transformations.
- Put data sources into data.tf.
- Put Terraform check statements into checks.tf.
- Put outputs into outputs.tf.
- Cleanup unused variables and statements in terraform files when making changes.