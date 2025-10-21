# Terraform - Agent Guidelines
- The project is using OpenTofu instead of Terraform.
- Terratest is used for automated tests.
- For any change validate it using `task check-llm` command inside the appropriate terragrunt folder.
- Verify that resources specified in the root module (input main.tf or terragrunt.hcl) are visible in the plan.
- At the end, run `task fmt` to automatically format modules and `task docs` to generate documentation.

## Code Style Guidelines
- Prefer creating resources with awscc provider (AWS Cloud Control API). Use aws provider for data resources only.
- Resource naming: this for single resources, plural for collections (e.g., awscc_ec2_vpc.this, awscc_ec2_subnet.this).
- Variable names: snake_case, descriptive and consistent with AWS terminology.
- Avoid modifying variables structure inside the root module (input main.tf or terragrunt.hcl) unless explicitly asked.
- Tags: merge common_tags with resource-specific tags using merge() function.
- Use for_each for multiple resources, count for conditional single resources.
- When terraform logical id consists of multiple parts, separate them with underscore.
- Create local variables in locals.tf for complex calculations and data transformations.
- Put data sources into data.tf.
- Put Terraform check statements into checks.tf.
- Put outputs into outputs.tf. Return full resources from provider when relevant. When there is a resource with "tags" attribute, convert it from list of maps into a single map.
- Cleanup unused variables and statements in terraform files when making changes.
