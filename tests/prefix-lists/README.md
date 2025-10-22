# Prefix Lists Module Tests

This directory contains Terratest tests for the prefix-lists module.

## Prerequisites

- OpenTofu (Terraform) installed
- Go 1.21 or later installed
- AWS credentials configured

## Running Tests

### Run all tests
```bash
cd tests/prefix-lists
go test -v
```

### Run specific test
```bash
cd tests/prefix-lists
go test -v -run TestPrefixListsBasic
```

### Run tests in parallel
```bash
cd tests/prefix-lists
go test -v -parallel 4
```

## Test Structure

The tests are organized as follows:

- `TestPrefixListsTerraformValidation`: Validates the Terraform configuration
- `TestPrefixListsWithVars`: Tests the module with different variable configurations
- `TestPrefixListsPlanOutput`: Verifies the plan output contains expected content

## Test Variable Files

The following test variable files are provided:

- `test_vars_ipv4_ipv6.tfvars`: Tests both IPv4 and IPv6 prefix lists
- `test_vars_empty.tfvars`: Tests empty prefix lists configuration
- `test_vars_tags.tfvars`: Tests prefix lists with custom tags
- `test_vars_default_multiple.tfvars`: Tests default max_entries_multiple (1)
- `test_vars_multiple_5.tfvars`: Tests max_entries_multiple of 5
- `test_vars_multiple_10.tfvars`: Tests max_entries_multiple of 10

## What the Tests Verify

1. **Terraform Validation**: Ensures the module configuration is valid
2. **Resource Creation**: Verifies that prefix lists are created as expected
3. **Variable Handling**: Tests different input configurations
4. **Plan Output**: Validates that the Terraform plan contains expected resources and configurations
5. **Max Entries Calculation**: Tests the max_entries_multiple logic

## Notes

- These tests use `tofu` (OpenTofu) instead of `terraform`
- Tests run `terraform plan` rather than `apply` to avoid creating real AWS resources
- The tests focus on validating the Terraform configuration and plan output
- For full end-to-end testing with actual AWS resource creation, you would need to modify the tests to use `terraform apply` and add AWS SDK calls to verify the created resources