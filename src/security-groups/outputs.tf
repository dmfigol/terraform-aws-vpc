output "this" {
  value = aws_security_group.this
}

output "security_groups" {
  value = {
    for name, sg in aws_security_group.this :
    name => {
      id      = sg.id
      egress  = sg.egress
      ingress = sg.ingress
    }
  }
}