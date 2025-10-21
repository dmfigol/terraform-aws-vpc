output "this" {
  value = {
    for k, v in awscc_ec2_vpc_endpoint.this :
    k => merge(v, { "tags" : {
      for tag in v.tags :
      tag.key => tag.value
    } })
  }
}

output "vpc_endpoints" {
  value = {
    for k, v in awscc_ec2_vpc_endpoint.this :
    k => merge(v, { "tags" : {
      for tag in v.tags :
      tag.key => tag.value
    } })
  }
}
