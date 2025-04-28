## Terraform Module for AWS Virtual Private Cloud (VPC)
A perfect abstraction for AWS VPC with the main goal of never blocking you from adding a new feature.

- IPv4 and IPv6 CIDR blocks (1 or more), static or from IPAM
- Subnets ipv4/ipv6/dual-stack
  - Subnets can be statically or dynamically automatically
  - subnets can be in local or wavelength zones 
- route tables, routes, internet gateway, virtual gateway
- NAT gateway
- Elastic IPs
- ingress routing
- Attachments: transit gateway, cloudwan
- DNS: Route53 profile association
- Endpoints:
  - gateway
  - interface
  - resource
  - service network
  - gateway load balancer endpoint
- Security groups
- Network Access lists
- VPC flow logs 