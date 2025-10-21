output "prefix_lists" {
  description = "Map of created prefix lists"
  value       = aws_ec2_managed_prefix_list.this
}