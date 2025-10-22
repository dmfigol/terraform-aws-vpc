package prefixlists_test

import (
	"os"
	"os/exec"
	"strings"
	"testing"
)

// TestPrefixListsTerraformValidation tests that the Terraform configuration is valid
func TestPrefixListsTerraformValidation(t *testing.T) {
	// Change to the module directory
	originalDir, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get current directory: %v", err)
	}
	defer os.Chdir(originalDir)

	err = os.Chdir("../../src/prefix-lists")
	if err != nil {
		t.Fatalf("Failed to change to module directory: %v", err)
	}

	// Run terraform init
	initCmd := exec.Command("tofu", "init")
	initOutput, err := initCmd.CombinedOutput()
	if err != nil {
		t.Fatalf("terraform init failed: %v\nOutput: %s", err, string(initOutput))
	}

	// Run terraform validate
	validateCmd := exec.Command("tofu", "validate")
	validateOutput, err := validateCmd.CombinedOutput()
	if err != nil {
		t.Fatalf("terraform validate failed: %v\nOutput: %s", err, string(validateOutput))
	}
}

// TestPrefixListsWithVars tests the module with different variable configurations
func TestPrefixListsWithVars(t *testing.T) {
	testCases := []struct {
		name    string
		varFile string
	}{
		{
			name:    "IPv4 and IPv6 prefix lists",
			varFile: "test_vars_ipv4_ipv6.tfvars",
		},
		{
			name:    "Empty prefix lists",
			varFile: "test_vars_empty.tfvars",
		},
		{
			name:    "Tagged prefix lists",
			varFile: "test_vars_tags.tfvars",
		},
		{
			name:    "Default multiple",
			varFile: "test_vars_default_multiple.tfvars",
		},
		{
			name:    "Multiple of 5",
			varFile: "test_vars_multiple_5.tfvars",
		},
		{
			name:    "Multiple of 10",
			varFile: "test_vars_multiple_10.tfvars",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Change to the test directory
			originalDir, err := os.Getwd()
			if err != nil {
				t.Fatalf("Failed to get current directory: %v", err)
			}
			defer os.Chdir(originalDir)

			// Change to the module directory
			err = os.Chdir("../../src/prefix-lists")
			if err != nil {
				t.Fatalf("Failed to change to module directory: %v", err)
			}

			// Run terraform plan with the test variables
			planCmd := exec.Command("tofu", "plan", "-var-file", "../../tests/prefix-lists/"+tc.varFile)
			planOutput, err := planCmd.CombinedOutput()
			if err != nil {
				t.Fatalf("terraform plan failed for %s: %v\nOutput: %s", tc.varFile, err, string(planOutput))
			}

			// Basic validation: check that plan output contains expected resources
			outputStr := string(planOutput)

			// Check for AWS managed prefix list resources
			if strings.Contains(tc.varFile, "empty") {
				// For empty config, should not create any resources
				if strings.Contains(outputStr, "aws_ec2_managed_prefix_list") {
					t.Errorf("Expected no resources for empty config, but found aws_ec2_managed_prefix_list in plan output")
				}
			} else {
				// For non-empty configs, should create prefix list resources
				if !strings.Contains(outputStr, "aws_ec2_managed_prefix_list") {
					t.Errorf("Expected aws_ec2_managed_prefix_list in plan output for %s", tc.varFile)
				}
			}

			// Check for expected prefix list names in the output
			if strings.Contains(tc.varFile, "ipv4_ipv6") {
				if !strings.Contains(outputStr, "test-ipv4-pl") || !strings.Contains(outputStr, "test-ipv6-pl") {
					t.Errorf("Expected prefix list names in plan output for %s", tc.varFile)
				}
			}

			if strings.Contains(tc.varFile, "tags") {
				if !strings.Contains(outputStr, "test-tagged-pl") {
					t.Errorf("Expected test-tagged-pl in plan output for %s", tc.varFile)
				}
			}

			if strings.Contains(tc.varFile, "multiple") {
				if !strings.Contains(outputStr, "test-max-entries-pl") {
					t.Errorf("Expected test-max-entries-pl in plan output for %s", tc.varFile)
				}
			}
		})
	}
}

// TestPrefixListsPlanOutput tests that the plan output contains expected content
func TestPrefixListsPlanOutput(t *testing.T) {
	// Change to the module directory
	originalDir, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get current directory: %v", err)
	}
	defer os.Chdir(originalDir)

	// Change to the module directory
	err = os.Chdir("../../src/prefix-lists")
	if err != nil {
		t.Fatalf("Failed to change to module directory: %v", err)
	}

	// Test with the IPv4/IPv6 configuration
	planCmd := exec.Command("tofu", "plan", "-var-file", "../../tests/prefix-lists/test_vars_ipv4_ipv6.tfvars")
	planOutput, err := planCmd.CombinedOutput()
	if err != nil {
		t.Fatalf("terraform plan failed: %v\nOutput: %s", err, string(planOutput))
	}

	outputStr := string(planOutput)

	// Verify plan output contains expected elements
	expectedStrings := []string{
		"aws_ec2_managed_prefix_list",
		"test-ipv4-pl",
		"test-ipv6-pl",
		"IPv4",
		"IPv6",
		"max_entries",
	}

	for _, expected := range expectedStrings {
		if !strings.Contains(outputStr, expected) {
			t.Errorf("Expected plan output to contain '%s', but it didn't", expected)
		}
	}

	// Verify specific CIDR blocks are mentioned
	expectedCIDRs := []string{
		"2.2.2.2/32",
		"8.8.8.8/32",
		"2001::/48",
		"2002::/48",
	}

	for _, expectedCIDR := range expectedCIDRs {
		if !strings.Contains(outputStr, expectedCIDR) {
			t.Errorf("Expected plan output to contain CIDR '%s', but it didn't", expectedCIDR)
		}
	}
}
