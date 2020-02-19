resource "aws_network_acl" "nat_network_acl" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.nat_subnet.*.id

  # egress to the whole internet

  egress {
    rule_no    = 200
    action     = "allow"
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  # ingress from whole internet

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    "Name" = "${var.project_name}-nat-network-acl",
  }
}

resource "aws_network_acl" "balancer_network_acl" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.balancer_subnet.*.id

  # egress to the whole internet

  egress {
    rule_no    = 200
    action     = "allow"
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  # ingress from whole internet

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    "Name" = "${var.project_name}-balancer-network-acl",
  }
}

resource "aws_network_acl" "node_network_acl" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.node_subnet.*.id

  # egress to vpc local

  egress {
    rule_no    = 200
    action     = "allow"
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0" # aws_vpc.vpc.cidr_block
  }

  # ingress from vpc local

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = -1
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0" # aws_vpc.vpc.cidr_block
    # 172.17.0.0/16 ?
  }

  tags = {
    "Name" = "${var.project_name}-node-network-acl",
  }
}
