# Security Groups Module Tests

This directory contains comprehensive tests for the security-groups Terraform module using Terratest.

## Test Coverage

The test suite covers the following scenarios:

### 1. Comma-Separated Ports
- **Test**: `TestCommaSeparatedPorts`
- **File**: `test_vars_comma_separated_ports.tfvars`
- **Description**: Validates that security group rules correctly handle comma-separated port definitions (e.g., "443,8080,9000")
- **Verification**: Checks that separate rules are created for each port in the list

### 2. Security Group Reference by Name
- **Test**: `TestSecurityGroupReferenceByName`
- **File**: `test_vars_sg_reference_by_name.tfvars`
- **Description**: Tests the `sg@name` notation for referencing other security groups in the same configuration
- **Verification**: Ensures `source_security_group_id` is set correctly and other fields (cidr_ip, prefix_list_id) are nil

### 3. Security Group Reference by ID
- **Test**: `TestSecurityGroupReferenceById`
- **File**: `test_vars_sg_reference_by_id.tfvars`
- **Description**: Tests direct security group ID references (e.g., "sg-0123456789abcdef0")
- **Verification**: Validates that external security group IDs are correctly assigned

### 4. Prefix List Reference by Name
- **Test**: `TestPrefixListReferenceByName`
- **File**: `test_vars_pl_reference_by_name.tfvars`
- **Description**: Tests the `pl@name` notation for referencing prefix lists by name
- **Verification**: Confirms that prefix list names are resolved to IDs from the `prefix_lists` variable

### 5. Prefix List Reference by ID
- **Test**: `TestPrefixListReferenceById`
- **File**: `test_vars_pl_reference_by_id.tfvars`
- **Description**: Tests direct prefix list ID references (e.g., "pl-0123456789abcdef0")
- **Verification**: Ensures prefix list IDs are correctly assigned to rules

### 6. IPv6 Sources and Destinations
- **Test**: `TestIPv6SourcesAndDestinations`
- **File**: `test_vars_ipv6_sources.tfvars`
- **Description**: Validates IPv6 CIDR blocks in security group rules
- **Verification**: Checks that `cidr_ipv_6` is set correctly and other fields are nil

### 7. Mixed References
- **Test**: `TestMixedReferences`
- **File**: `test_vars_mixed_references.tfvars`
- **Description**: Tests complex scenarios with multiple reference types (CIDR, sg@name, sg-id, pl@name, pl-id)
- **Verification**: Ensures all reference types work correctly in combination

### 8. Invalid Security Group Reference (Validation Test)
- **Test**: `TestInvalidSecurityGroupReference`
- **File**: `test_vars_invalid_sg_reference.tfvars`
- **Description**: Tests that referencing a non-existent security group by name fails validation
- **Expected Result**: Terraform plan should fail with a validation error

### 9. Invalid Prefix List Reference (Validation Test)
- **Test**: `TestInvalidPrefixListReference`
- **File**: `test_vars_invalid_pl_reference.tfvars`
- **Description**: Tests that referencing a non-existent prefix list by name fails validation
- **Expected Result**: Terraform plan should fail with a validation error

## Running the Tests

### Prerequisites
- Go 1.21 or later
- OpenTofu (tofu) installed and available in PATH

### Run All Tests
```bash
cd tests/security-groups
go test -v -timeout 30m
```

### Run Specific Test
```bash
cd tests/security-groups
go test -v -run TestCommaSeparatedPorts
```

### Run Without Cache
```bash
cd tests/security-groups
go test -v -count=1
```

## Test Methodology

The tests use the following approaches:

1. **JSON Plan Parsing**: Most tests parse the Terraform plan JSON output to verify exact field values
2. **Validation Testing**: Invalid configuration tests check that Terraform validation catches errors
3. **Resource Counting**: Tests verify the correct number of resources are created
4. **Field Assertions**: Tests check that specific fields are set or nil as expected

## Variable Files

Each test case has a corresponding `.tfvars` file that defines the test scenario. These files are located in the `tests/security-groups/` directory.

## Notes

- Tests use `tofu` command (OpenTofu) instead of `terraform`
- Tests run `tofu init` automatically before each plan
- Tests clean up by changing back to the original directory after execution
- The test suite validates both positive (should work) and negative (should fail) scenarios
