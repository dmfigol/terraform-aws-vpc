# 0.2.1
- Remove `availability_mode` from `nat_gateways` variable; now derived from `subnet` presence (zonal if subnet provided, regional otherwise)
- Add `nat_gateways` output

# 0.2.0
- Add cross-region VPC interface endpoints
- Add regional NAT Gateway
- Enforce source and destination field for security group rule

# 0.1.0
Initial release supporting:
- VPC
- Subnets (static or dynamic CIDRs)
- Route Tables
- Routes (including route references)
- Elastic IPs and NAT Gateway (zonal private and public)
- IGW/EIGW/VGW
- TGW and Cloud WAN attachments
- Route 53 Private Hosted Zone and Profile association
- VPC endpoints (interface and gateway)
- Security groups 
- Prefix lists
