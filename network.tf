resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
  }
}


# define a network gateway that can talk to the internet in a public subnet

resource "aws_subnet" "pub_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.0.100.0/24"
  map_public_ip_on_launch = false

  tags = {
    "name" = "${var.project_name}-pub-subnet",
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared",
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_network_acl" "pub_network_acl" {
  vpc_id       = aws_vpc.vpc.id
  subnet_ids   = [aws_subnet.pub_subnet.id]

  ingress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = -1
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = -1
    from_port  = 0
    to_port    = 0
  }

  tags = {
    "name"      = "${var.project_name}-pub-network-acl"
  }
}

resource "aws_internet_gateway" "pub_internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "name" = "${var.project_name}-internet-gateway",
  }
}

resource "aws_route_table" "pub_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pub_internet_gateway.id
  }

  tags = {
    "name" = "${var.project_name}-pub-route-table",
  }
}

resource "aws_route_table_association" "pub_route_table_association" {
  subnet_id      = aws_subnet.pub_subnet.id
  route_table_id = aws_route_table.pub_route_table.id
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = var.elastic_ip_id
  subnet_id     = aws_subnet.pub_subnet.id

  tags = {
    "name" = "${var.project_name}-nat-gateway",
  }
}




# define private subnets with a NAT to allow them to talk to the world

resource "aws_subnet" "prv_subnet" {
  count = 3

  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index}.0/24"  
  map_public_ip_on_launch = false

  tags = {
    "name" = "${var.project_name}-prv-subnet-${count.index}",
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared",
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_network_acl" "prv_network_acl" {
  vpc_id       = aws_vpc.vpc.id
  subnet_ids   = aws_subnet.prv_subnet.*.id

  ingress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.100.0/24"
    protocol   = -1
    from_port  = 0
    to_port    = 0
  }

  ingress {
    rule_no    = 101
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    protocol   = -1
    from_port  = 0
    to_port    = 0
  }

  ingress {
    rule_no    = 1001
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = -1
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.0.100.0/24"
    protocol   = -1
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 201
    action     = "allow"
    protocol   = -1
    cidr_block = "10.0.0.0/16"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 2001
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = -1
    from_port  = 0
    to_port    = 0
  }

  tags = {
    "name"      = "${var.project_name}-prv-network-acl"
  }
}

resource "aws_route_table" "prv_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    "name" = "${var.project_name}-prv-route-table",
  }
}

resource "aws_route_table_association" "prv_route_table_association" {
  count = 3

  subnet_id      = aws_subnet.prv_subnet.*.id[count.index]
  route_table_id = aws_route_table.prv_route_table.id
}
