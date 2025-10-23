package securitygroups_test

import (
	"encoding/json"
	"os"
	"os/exec"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestSecurityGroupsTerraformValidation tests that the Terraform configuration is valid
func TestSecurityGroupsTerraformValidation(t *testing.T) {
	originalDir, err := os.Getwd()
	require.NoError(t, err)
	defer os.Chdir(originalDir)

	err = os.Chdir("../../src/security-groups")
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

// TestCommaSeparatedPorts tests security group rules with comma-separated ports
func TestCommaSeparatedPorts(t *testing.T) {
	plan := runTerraformPlan(t, "test_vars_comma_separated_ports.tfvars")

	// Check that all three inbound ports generate separate rules
	ingressRules := filterResourcesByType(plan, "awscc_ec2_security_group_ingress")
	assert.GreaterOrEqual(t, len(ingressRules), 3, "Expected at least 3 ingress rules for ports 443, 8080, 9000")

	// Verify specific port rules exist
	var foundPorts []int
	for _, rule := range ingressRules {
		if change, ok := rule["change"].(map[string]interface{}); ok {
			if after, ok := change["after"].(map[string]interface{}); ok {
				if fromPort, ok := after["from_port"].(float64); ok {
					foundPorts = append(foundPorts, int(fromPort))
				}
			}
		}
	}

	assert.Contains(t, foundPorts, 443, "Expected port 443 in ingress rules")
	assert.Contains(t, foundPorts, 8080, "Expected port 8080 in ingress rules")
	assert.Contains(t, foundPorts, 9000, "Expected port 9000 in ingress rules")

	// Check egress rules
	egressRules := filterResourcesByType(plan, "awscc_ec2_security_group_egress")
	assert.GreaterOrEqual(t, len(egressRules), 3, "Expected at least 3 egress rules for ports 80, 443, 8443")
}

// TestSecurityGroupReferenceByName tests sg@ notation for referencing security groups by name
func TestSecurityGroupReferenceByName(t *testing.T) {
	plan := runTerraformPlan(t, "test_vars_sg_reference_by_name.tfvars")

	// Check that security groups are created
	securityGroups := filterResourcesByType(plan, "awscc_ec2_security_group")
	assert.GreaterOrEqual(t, len(securityGroups), 3, "Expected at least 3 security groups: app-sg, lb-sg, db-sg")

	// Check ingress rule for app-sg referencing lb-sg
	ingressRules := filterResourcesByType(plan, "awscc_ec2_security_group_ingress")
	
	foundAppToLbRule := false
	for _, rule := range ingressRules {
		if change, ok := rule["change"].(map[string]interface{}); ok {
			if after, ok := change["after"].(map[string]interface{}); ok {
				// Check if this is the app-sg rule referencing lb-sg
				if port, ok := after["from_port"].(float64); ok && int(port) == 8080 {
					// Check if source_security_group_id will be set (in after_unknown because the SG doesn't exist yet)
					if afterUnknown, ok := change["after_unknown"].(map[string]interface{}); ok {
						if sgUnknown, exists := afterUnknown["source_security_group_id"]; exists && sgUnknown == true {
							foundAppToLbRule = true
							// Verify cidr_ip is also unknown (both will be computed, but only sg id will actually be set)
							assert.NotNil(t, afterUnknown["cidr_ip"], "Expected cidr_ip to be in after_unknown")
						}
					}
				}
			}
		}
	}
	assert.True(t, foundAppToLbRule, "Expected to find ingress rule for app-sg referencing lb-sg")

	// Check egress rule for app-sg referencing db-sg
	egressRules := filterResourcesByType(plan, "awscc_ec2_security_group_egress")
	
	foundAppToDbRule := false
	for _, rule := range egressRules {
		if change, ok := rule["change"].(map[string]interface{}); ok {
			if after, ok := change["after"].(map[string]interface{}); ok {
				// Check if this is the app-sg egress rule to db-sg
				if port, ok := after["from_port"].(float64); ok && int(port) == 5432 {
					// Check if destination_security_group_id will be set (in after_unknown)
					if afterUnknown, ok := change["after_unknown"].(map[string]interface{}); ok {
						if sgUnknown, exists := afterUnknown["destination_security_group_id"]; exists && sgUnknown == true {
							foundAppToDbRule = true
						}
					}
				}
			}
		}
	}
	assert.True(t, foundAppToDbRule, "Expected to find egress rule for app-sg referencing db-sg")
}

// TestSecurityGroupReferenceById tests sg-xxxxx notation for referencing external security groups by ID
func TestSecurityGroupReferenceById(t *testing.T) {
	plan := runTerraformPlan(t, "test_vars_sg_reference_by_id.tfvars")

	// Check ingress rule with external SG ID
	ingressRules := filterResourcesByType(plan, "awscc_ec2_security_group_ingress")
	
	foundExternalSgIngress := false
	for _, rule := range ingressRules {
		if change, ok := rule["change"].(map[string]interface{}); ok {
			if after, ok := change["after"].(map[string]interface{}); ok {
				if sgId, ok := after["source_security_group_id"].(string); ok {
					if strings.HasPrefix(sgId, "sg-") {
						foundExternalSgIngress = true
						assert.Equal(t, "sg-0123456789abcdef0", sgId, "Expected specific external security group ID")
						// Verify the source_security_group_id is set (not cidr_ip)
						assert.Nil(t, after["cidr_ip"], "Expected cidr_ip to be nil when using sg-id reference")
						assert.Nil(t, after["source_prefix_list_id"], "Expected source_prefix_list_id to be nil when using sg-id reference")
					}
				}
			}
		}
	}
	assert.True(t, foundExternalSgIngress, "Expected to find ingress rule with external security group ID")

	// Check egress rule with external SG ID
	egressRules := filterResourcesByType(plan, "awscc_ec2_security_group_egress")
	
	foundExternalSgEgress := false
	for _, rule := range egressRules {
		if change, ok := rule["change"].(map[string]interface{}); ok {
			if after, ok := change["after"].(map[string]interface{}); ok {
				if sgId, ok := after["destination_security_group_id"].(string); ok {
					if strings.HasPrefix(sgId, "sg-") {
						foundExternalSgEgress = true
						assert.Equal(t, "sg-abcdef0123456789a", sgId, "Expected specific external security group ID")
						// Verify the destination_security_group_id is set (not cidr_ip)
						assert.Nil(t, after["cidr_ip"], "Expected cidr_ip to be nil when using sg-id reference")
						assert.Nil(t, after["destination_prefix_list_id"], "Expected destination_prefix_list_id to be nil when using sg-id reference")
					}
				}
			}
		}
	}
	assert.True(t, foundExternalSgEgress, "Expected to find egress rule with external security group ID")
}

// TestPrefixListReferenceByName tests pl@ notation for referencing prefix lists by name
func TestPrefixListReferenceByName(t *testing.T) {
	plan := runTerraformPlan(t, "test_vars_pl_reference_by_name.tfvars")

	// Check ingress rule with prefix list reference by name
	ingressRules := filterResourcesByType(plan, "awscc_ec2_security_group_ingress")
	
	foundPrefixListIngress := false
	for _, rule := range ingressRules {
		if change, ok := rule["change"].(map[string]interface{}); ok {
			if after, ok := change["after"].(map[string]interface{}); ok {
				if plId, ok := after["source_prefix_list_id"].(string); ok && plId != "" {
					foundPrefixListIngress = true
					// Verify it resolves to the correct prefix list ID from the variable
					assert.Equal(t, "pl-0123456789abcdef0", plId, "Expected prefix list ID from pl@office-ips reference")
					// Verify only source_prefix_list_id is set
					assert.Nil(t, after["cidr_ip"], "Expected cidr_ip to be nil when using prefix list reference")
					assert.Nil(t, after["source_security_group_id"], "Expected source_security_group_id to be nil when using prefix list reference")
				}
			}
		}
	}
	assert.True(t, foundPrefixListIngress, "Expected to find ingress rule with prefix list reference")

	// Check egress rule with prefix list reference by name
	egressRules := filterResourcesByType(plan, "awscc_ec2_security_group_egress")
	
	foundPrefixListEgress := false
	for _, rule := range egressRules {
		if change, ok := rule["change"].(map[string]interface{}); ok {
			if after, ok := change["after"].(map[string]interface{}); ok {
				if plId, ok := after["destination_prefix_list_id"].(string); ok && plId != "" {
					foundPrefixListEgress = true
					// Verify it resolves to the correct prefix list ID from the variable
					assert.Equal(t, "pl-abcdef0123456789a", plId, "Expected prefix list ID from pl@aws-services reference")
					// Verify only destination_prefix_list_id is set
					assert.Nil(t, after["cidr_ip"], "Expected cidr_ip to be nil when using prefix list reference")
					assert.Nil(t, after["destination_security_group_id"], "Expected destination_security_group_id to be nil when using prefix list reference")
				}
			}
		}
	}
	assert.True(t, foundPrefixListEgress, "Expected to find egress rule with prefix list reference")
}

// TestPrefixListReferenceById tests pl-xxxxx notation for referencing prefix lists by ID
func TestPrefixListReferenceById(t *testing.T) {
	plan := runTerraformPlan(t, "test_vars_pl_reference_by_id.tfvars")

	// Check ingress rule with prefix list ID
	ingressRules := filterResourcesByType(plan, "awscc_ec2_security_group_ingress")
	
	foundPrefixListIngress := false
	for _, rule := range ingressRules {
		if change, ok := rule["change"].(map[string]interface{}); ok {
			if after, ok := change["after"].(map[string]interface{}); ok {
				if plId, ok := after["source_prefix_list_id"].(string); ok && plId != "" {
					foundPrefixListIngress = true
					assert.Equal(t, "pl-0123456789abcdef0", plId, "Expected specific prefix list ID")
					// Verify only source_prefix_list_id is set
					assert.Nil(t, after["cidr_ip"], "Expected cidr_ip to be nil when using prefix list ID")
					assert.Nil(t, after["source_security_group_id"], "Expected source_security_group_id to be nil when using prefix list ID")
				}
			}
		}
	}
	assert.True(t, foundPrefixListIngress, "Expected to find ingress rule with prefix list ID")

	// Check egress rule with prefix list ID
	egressRules := filterResourcesByType(plan, "awscc_ec2_security_group_egress")
	
	foundPrefixListEgress := false
	for _, rule := range egressRules {
		if change, ok := rule["change"].(map[string]interface{}); ok {
			if after, ok := change["after"].(map[string]interface{}); ok {
				if plId, ok := after["destination_prefix_list_id"].(string); ok && plId != "" {
					foundPrefixListEgress = true
					assert.Equal(t, "pl-fedcba9876543210f", plId, "Expected specific prefix list ID")
					// Verify only destination_prefix_list_id is set
					assert.Nil(t, after["cidr_ip"], "Expected cidr_ip to be nil when using prefix list ID")
					assert.Nil(t, after["destination_security_group_id"], "Expected destination_security_group_id to be nil when using prefix list ID")
				}
			}
		}
	}
	assert.True(t, foundPrefixListEgress, "Expected to find egress rule with prefix list ID")
}

// TestIPv6SourcesAndDestinations tests IPv6 CIDR blocks in security group rules
func TestIPv6SourcesAndDestinations(t *testing.T) {
	plan := runTerraformPlan(t, "test_vars_ipv6_sources.tfvars")

	// Check ingress rules with IPv6 CIDRs
	ingressRules := filterResourcesByType(plan, "awscc_ec2_security_group_ingress")
	
	foundIPv6Rules := 0
	var foundIPv6CIDRs []string
	for _, rule := range ingressRules {
		if change, ok := rule["change"].(map[string]interface{}); ok {
			if after, ok := change["after"].(map[string]interface{}); ok {
				if ipv6Cidr, ok := after["cidr_ipv_6"].(string); ok && ipv6Cidr != "" {
					foundIPv6Rules++
					foundIPv6CIDRs = append(foundIPv6CIDRs, ipv6Cidr)
					// Verify only cidr_ipv_6 is set (not cidr_ip or source_security_group_id)
					assert.Nil(t, after["cidr_ip"], "Expected cidr_ip to be nil when using IPv6 CIDR")
					assert.Nil(t, after["source_security_group_id"], "Expected source_security_group_id to be nil when using IPv6 CIDR")
					assert.Nil(t, after["source_prefix_list_id"], "Expected source_prefix_list_id to be nil when using IPv6 CIDR")
				}
			}
		}
	}
	assert.GreaterOrEqual(t, foundIPv6Rules, 3, "Expected at least 3 IPv6 ingress rules")
	assert.Contains(t, foundIPv6CIDRs, "2001:db8::/32", "Expected IPv6 CIDR 2001:db8::/32")

	// Check egress rules with IPv6 CIDRs
	egressRules := filterResourcesByType(plan, "awscc_ec2_security_group_egress")
	
	foundIPv6Egress := 0
	var foundIPv6EgressCIDRs []string
	for _, rule := range egressRules {
		if change, ok := rule["change"].(map[string]interface{}); ok {
			if after, ok := change["after"].(map[string]interface{}); ok {
				if ipv6Cidr, ok := after["cidr_ipv_6"].(string); ok && ipv6Cidr != "" {
					foundIPv6Egress++
					foundIPv6EgressCIDRs = append(foundIPv6EgressCIDRs, ipv6Cidr)
					// Verify only cidr_ipv_6 is set (not cidr_ip or destination_security_group_id)
					assert.Nil(t, after["cidr_ip"], "Expected cidr_ip to be nil when using IPv6 CIDR")
					assert.Nil(t, after["destination_security_group_id"], "Expected destination_security_group_id to be nil when using IPv6 CIDR")
					assert.Nil(t, after["destination_prefix_list_id"], "Expected destination_prefix_list_id to be nil when using IPv6 CIDR")
				}
			}
		}
	}
	assert.GreaterOrEqual(t, foundIPv6Egress, 2, "Expected at least 2 IPv6 egress rules")
	assert.Contains(t, foundIPv6EgressCIDRs, "::/0", "Expected IPv6 CIDR ::/0")
}

// TestInvalidSecurityGroupReference tests that referencing a non-existent security group fails validation
func TestInvalidSecurityGroupReference(t *testing.T) {
	originalDir, err := os.Getwd()
	require.NoError(t, err)
	defer os.Chdir(originalDir)

	err = os.Chdir("../../src/security-groups")
	require.NoError(t, err)

	// Run terraform plan with invalid SG reference - expect it to fail
	planCmd := exec.Command("tofu", "plan", "-var-file", "../../tests/security-groups/test_vars_invalid_sg_reference.tfvars")
	planOutput, err := planCmd.CombinedOutput()
	
	// Expect the command to fail due to validation error
	assert.Error(t, err, "Expected terraform plan to fail with invalid security group reference")
	
	// Check that the error message mentions the validation failure
	outputStr := string(planOutput)
	assert.Contains(t, outputStr, "security group", "Expected error message to mention security group")
	assert.Contains(t, outputStr, "does not exist", "Expected error message to mention non-existent reference")
}

// TestInvalidPrefixListReference tests that referencing a non-existent prefix list fails validation
func TestInvalidPrefixListReference(t *testing.T) {
	originalDir, err := os.Getwd()
	require.NoError(t, err)
	defer os.Chdir(originalDir)

	err = os.Chdir("../../src/security-groups")
	require.NoError(t, err)

	// Run terraform plan with invalid PL reference - expect it to fail
	planCmd := exec.Command("tofu", "plan", "-var-file", "../../tests/security-groups/test_vars_invalid_pl_reference.tfvars")
	planOutput, err := planCmd.CombinedOutput()
	
	// Expect the command to fail due to validation error
	assert.Error(t, err, "Expected terraform plan to fail with invalid prefix list reference")
	
	// Check that the error message mentions the validation failure
	outputStr := string(planOutput)
	assert.Contains(t, outputStr, "prefix list", "Expected error message to mention prefix list")
	assert.Contains(t, outputStr, "does not exist", "Expected error message to mention non-existent reference")
}

// TestMixedReferences tests a complex scenario with multiple reference types
func TestMixedReferences(t *testing.T) {
	plan := runTerraformPlan(t, "test_vars_mixed_references.tfvars")

	// Verify multiple rule types are created
	ingressRules := filterResourcesByType(plan, "awscc_ec2_security_group_ingress")
	
	// Should have 4 ingress rules (1 port range x 4 sources: IPv4 CIDR, sg@name, pl@name, pl-id)
	assert.Equal(t, 4, len(ingressRules), "Expected exactly 4 ingress rules with mixed references")

	// Count different reference types
	var cidrRules, sgRules, plRules int
	for _, rule := range ingressRules {
		if change, ok := rule["change"].(map[string]interface{}); ok {
			if after, ok := change["after"].(map[string]interface{}); ok {
				// Check actual values first
				if cidr, ok := after["cidr_ip"].(string); ok && cidr != "" {
					cidrRules++
				}
				if sgId, ok := after["source_security_group_id"].(string); ok && sgId != "" {
					sgRules++
				}
				if plId, ok := after["source_prefix_list_id"].(string); ok && plId != "" {
					plRules++
				}
			}
			// Also check after_unknown for values that will be computed
			if afterUnknown, ok := change["after_unknown"].(map[string]interface{}); ok {
				// If source_security_group_id is unknown and cidr_ip is also unknown, it means sg will be set
				if _, sgExists := afterUnknown["source_security_group_id"]; sgExists {
					if after, ok := change["after"].(map[string]interface{}); ok {
						// Check if this rule has no cidr or pl values set
						cidr, hasCidr := after["cidr_ip"].(string)
						pl, hasPl := after["source_prefix_list_id"].(string)
						if (!hasCidr || cidr == "") && (!hasPl || pl == "") {
							sgRules++
						}
					}
				}
			}
		}
	}

	assert.Equal(t, 1, cidrRules, "Expected exactly 1 CIDR-based rule")
	assert.Equal(t, 1, sgRules, "Expected exactly 1 security group-based rule")
	assert.Equal(t, 2, plRules, "Expected exactly 2 prefix list-based rules")
}

// Helper function to run terraform plan and parse JSON output
func runTerraformPlan(t *testing.T, varFile string) []map[string]interface{} {
	originalDir, err := os.Getwd()
	require.NoError(t, err)
	defer os.Chdir(originalDir)

	err = os.Chdir("../../src/security-groups")
	require.NoError(t, err)

	// Run terraform init first (if not already done)
	initCmd := exec.Command("tofu", "init")
	_, _ = initCmd.CombinedOutput() // Ignore error, may already be initialized

	// Run terraform plan and save to file
	planFile := "/tmp/tfplan-" + strings.Replace(varFile, ".tfvars", ".tfplan", 1)
	planCmd := exec.Command("tofu", "plan", "-var-file", "../../tests/security-groups/"+varFile, "-out", planFile)
	planOutput, err := planCmd.CombinedOutput()
	require.NoError(t, err, "terraform plan failed: %s", string(planOutput))

	// Run terraform show -json on the plan file
	showCmd := exec.Command("tofu", "show", "-json", planFile)
	showOutput, err := showCmd.CombinedOutput()
	require.NoError(t, err, "terraform show failed: %s", string(showOutput))

	// Parse JSON output
	var planData map[string]interface{}
	err = json.Unmarshal(showOutput, &planData)
	require.NoError(t, err, "failed to parse JSON output")

	// Extract resource_changes
	resourceChanges, ok := planData["resource_changes"].([]interface{})
	if !ok {
		return []map[string]interface{}{}
	}

	var resources []map[string]interface{}
	for _, rc := range resourceChanges {
		if rcMap, ok := rc.(map[string]interface{}); ok {
			resources = append(resources, rcMap)
		}
	}

	return resources
}

// Helper function to filter resources by type
func filterResourcesByType(resources []map[string]interface{}, resourceType string) []map[string]interface{} {
	var filtered []map[string]interface{}
	for _, resource := range resources {
		if rt, ok := resource["type"].(string); ok && rt == resourceType {
			filtered = append(filtered, resource)
		}
	}
	return filtered
}

// TestAllVarFiles runs a basic plan test for all var files to ensure they're valid
func TestAllVarFiles(t *testing.T) {
	testCases := []struct {
		name          string
		varFile       string
		shouldSucceed bool
	}{
		{"Comma Separated Ports", "test_vars_comma_separated_ports.tfvars", true},
		{"SG Reference By Name", "test_vars_sg_reference_by_name.tfvars", true},
		{"SG Reference By ID", "test_vars_sg_reference_by_id.tfvars", true},
		{"PL Reference By Name", "test_vars_pl_reference_by_name.tfvars", true},
		{"PL Reference By ID", "test_vars_pl_reference_by_id.tfvars", true},
		{"IPv6 Sources", "test_vars_ipv6_sources.tfvars", true},
		{"Mixed References", "test_vars_mixed_references.tfvars", true},
		{"Invalid SG Reference", "test_vars_invalid_sg_reference.tfvars", false},
		{"Invalid PL Reference", "test_vars_invalid_pl_reference.tfvars", false},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			originalDir, err := os.Getwd()
			require.NoError(t, err)
			defer os.Chdir(originalDir)

			err = os.Chdir("../../src/security-groups")
			require.NoError(t, err)

			// Run terraform plan
			planCmd := exec.Command("tofu", "plan", "-var-file", "../../tests/security-groups/"+tc.varFile)
			planOutput, err := planCmd.CombinedOutput()

			if tc.shouldSucceed {
				assert.NoError(t, err, "Expected plan to succeed for %s, but got error: %s", tc.varFile, string(planOutput))
			} else {
				assert.Error(t, err, "Expected plan to fail for %s", tc.varFile)
			}
		})
	}
}
