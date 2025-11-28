# VPC Module Tests

This directory contains tests for the VPC module.

## Test Cases

### Invalid NAT Gateway Reference
- **File**: `test_vars_invalid_natgw_reference.tfvars`
- **Purpose**: Tests that referencing a non-existent NAT gateway in routes fails with a proper validation error
- **Expected**: Plan should fail with validation error about missing NAT gateway

## Running Tests

```bash
cd tests/vpc
go test -v
```
