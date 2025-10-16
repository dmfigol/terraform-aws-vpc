data "aws_caller_identity" "current" {}

data "aws_availability_zones" "this" {
  state = "available"
}

data "aws_region" "current" {}

data "aws_route53_zone" "private_hosted_zones" {
  for_each = try(var.dns.private_hosted_zones, null) != null ? toset(var.dns.private_hosted_zones) : []

  name         = each.value
  private_zone = true
}