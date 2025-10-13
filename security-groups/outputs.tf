output "this" {
  value = {
    for k, v in awscc_ec2_security_group.this :
    k => merge(v, { "tags" : {
      for tag in v.tags :
      tag.key => tag.value
    } })
  }
}

output "security_groups" {
  value = {
    for name, sg in awscc_ec2_security_group.this :
    name => {
      id      = sg.id
      egress  = sg.security_group_egress
      ingress = sg.security_group_ingress
    }
  }
}