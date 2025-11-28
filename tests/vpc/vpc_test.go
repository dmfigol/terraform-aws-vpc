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

	// Run terraform plan with invalid NAT gateway reference
	planCmd := exec.Command("tofu", "plan", "-var-file", "../../tests/vpc/test_vars_invalid_natgw_reference.tfvars")
	planOutput, err := planCmd.CombinedOutput()

	outputStr := string(planOutput)

	// The plan is expected to fail due to invalid NAT gateway references
	// But we should still see the check block warning
	assert.Error(t, err, "Expected terraform plan to fail due to invalid NAT gateway references")

	// Check that the output contains the validation warning about NAT gateways
	assert.True(t,
		strings.Contains(outputStr, "Check block assertion failed") &&
			(strings.Contains(outputStr, "NAT gateway") || strings.Contains(outputStr, "nat gateway")),
		"Expected warning message about NAT gateway validation failure, got: %s", outputStr)

	// Also check for the specific error messages about invalid NAT gateway references
	assert.Contains(t, outputStr, "natgw@natgw1", "Expected error about natgw@natgw1 reference")
	assert.Contains(t, outputStr, "natgw@natgw2", "Expected error about natgw@natgw2 reference")
}

// TestAllVarFiles runs a basic plan test for all var files to ensure they're valid
func TestAllVarFiles(t *testing.T) {
	testCases := []struct {
		name          string
		varFile       string
		shouldSucceed bool
	}{
		{"Invalid NAT Gateway Reference", "test_vars_invalid_natgw_reference.tfvars", false}, // Should fail due to invalid NAT gateway references
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
