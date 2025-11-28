check "nat_gateway_references" {
  assert {
    condition = alltrue([
      for route in flatten([
        for rt_name, rt_config in var.route_tables : [
          for route in rt_config.routes : {
            next_hop = route.next_hop
          }
        ]
        ]) : (
        !startswith(route.next_hop, "natgw@") ||
        contains(keys(var.nat_gateways), split("@", route.next_hop)[1])
      )
    ])
    error_message = "One or more routes reference NAT gateways that do not exist. All 'natgw@<name>' references in routes must correspond to a defined NAT gateway in var.nat_gateways."
  }
}
