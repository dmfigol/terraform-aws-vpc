package vpc_test

import (
	"os"
	"os/exec"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestVpcTerraformValidation tests that the Terraform configuration is valid
func TestVpcTerraformValidation(t *testing.T) {
	originalDir, err := os.Getwd()
	require.NoError(t, err)
	defer os.Chdir(originalDir)

	err = os.Chdir("../../src/vpc")
	require.NoError(t, err)

	// Run terraform init
	initCmd := exec.Command("tofu", "init")
	initOutput, err := initCmd.CombinedOutput()
	require.NoError(t, err, "terraform init failed: %s", string(initOutput))

	// Run terraform validate
	validateCmd := exec.Command("tofu", "validate")
	validateOutput, err := validateCmd.CombinedOutput()
	require.NoError(t, err, "terraform validate failed: %s", string(validateOutput))
}

// TestInvalidNatGatewayReference tests that referencing a non-existent NAT gateway shows a validation warning
func TestInvalidNatGatewayReference(t *testing.T) {
	originalDir, err := os.Getwd()
	require.NoError(t, err)
	defer os.Chdir(originalDir)

	err = os.Chdir("../../src/vpc")
	require.NoError(t, err)

	// Run terraform plan with invalid NAT gateway reference - expect it to succeed with warning
	planCmd := exec.Command("tofu", "plan", "-var-file", "../../tests/vpc/test_vars_invalid_natgw_reference.tfvars")
	planOutput, err := planCmd.CombinedOutput()

	// Expect the command to succeed (warnings don't cause failures)
	assert.NoError(t, err, "Expected terraform plan to succeed (with warnings), but got error: %s", string(planOutput))

	// Check that the output contains the validation warning
	outputStr := string(planOutput)
	assert.True(t,
		strings.Contains(outputStr, "Check block assertion failed") &&
			(strings.Contains(outputStr, "NAT gateway") || strings.Contains(outputStr, "nat gateway")),
		"Expected warning message about NAT gateway validation failure, got: %s", outputStr)

	// Verify that routes referencing non-existent NAT gateways are filtered out
	// Only the public route should be created (using igw)
	assert.Contains(t, outputStr, "awscc_ec2_route.this[\"public_0.0.0.0/0\"]",
		"Expected public route to be created")
	assert.NotContains(t, outputStr, "awscc_ec2_route.this[\"private1_0.0.0.0/0\"]",
		"Expected private1 route with invalid NAT gateway to be filtered out")
	assert.NotContains(t, outputStr, "awscc_ec2_route.this[\"private2_0.0.0.0/0\"]",
		"Expected private2 route with invalid NAT gateway to be filtered out")
}

// TestAllVarFiles runs a basic plan test for all var files to ensure they're valid
func TestAllVarFiles(t *testing.T) {
	testCases := []struct {
		name          string
		varFile       string
		shouldSucceed bool
	}{
		{"Invalid NAT Gateway Reference", "test_vars_invalid_natgw_reference.tfvars", true}, // Should succeed with warning
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			originalDir, err := os.Getwd()
			require.NoError(t, err)
			defer os.Chdir(originalDir)

			err = os.Chdir("../../src/vpc")
			require.NoError(t, err)

			// Run terraform plan
			planCmd := exec.Command("tofu", "plan", "-var-file", "../../tests/vpc/"+tc.varFile)
			planOutput, err := planCmd.CombinedOutput()

			if tc.shouldSucceed {
				assert.NoError(t, err, "Expected plan to succeed for %s, but got error: %s", tc.varFile, string(planOutput))
			} else {
				assert.Error(t, err, "Expected plan to fail for %s", tc.varFile)
			}
		})
	}
}
