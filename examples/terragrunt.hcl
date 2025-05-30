# consume terraform module in neighboring folder and provide inputs

terraform {
    source = "${get_repo_root()}/module"
}

inputs = {
    aws_region = "eu-central-1"
    name = "unicorn-tf-app_dev"

    cidrs = {
        "ipv4": [
            {"cidr": "10.10.0.0/16"},  # {"size": 24, ipam_pool_id: pool-1234}
            {"cidr": "100.64.0.0/26"} 
        ],
        "ipv6": [
            {"size": 56},
            {"size": 56},
        ]
    }
    internet_gateway = {"tags": {"IgwKey": "IgwValue"}}
    virtual_gateway = {"tags": {"VgwKey": "VgwValue"}}
    egress_only_igw = {"tags": {"EigwKey": "EigwValue"}}

    subnets = [
        { "name": "int-az1", "az_id": "euc1-az1", "ipv4": {"size": 24}, "ipv6": {}, "route_table": "internal", "tags": {"SubnetTag": "SubnetValue"} },
        { "name": "int-az2", "az_id": "euc1-az2", "ipv4": {"size": 24}, "ipv6": {}, "route_table": "internal" },
        { "name": "ipv6only-az1", "az_id": "euc1-az1", "ipv6": {} },
        { "name": "ipv6only-az2", "az_id": "euc1-az2", "ipv6": {} },
        { "name": "attach-az1", "az_id": "euc1-az1", "ipv4": {"cidr": "100.64.0.0/28"}, "ipv6": {"cidr_num": 1} },
        { "name": "attach-az2", "az_id": "euc1-az2", "ipv4": {"cidr": "100.64.0.16/28"}, "ipv6": {"cidr_num": 1} },
    ]

    route_tables = {
        "internal": {"routes": [
            {"route": "0.0.0.0/0", "via": "@igw"},
            {"route": "::/0", "via": "@eigw"},
            {"route": "1.2.3.4/32", "via": "@vgw"},
        ]}
    }

    common_tags = {
        "Project": "unicorn-tf-app",
        "Environment": "dev", 
        "ManagedBy": "terraform",
    }
    vpc_tags = {
        "MyVPCTag": "MyVPCTagValue"
    }
}