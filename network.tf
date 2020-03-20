resource "aws_vpc" "vpc" {
  cidr_block                       = "10.0.0.0/16"
  enable_dns_support               = true
  enable_dns_hostnames             = true

  tags = {
    "Name" = "${var.project_name}-vpc",
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
  }
}

# gateway for traffic to leave the vpc
# only one exists for the whole vpc
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "${var.project_name}-internet-gateway",
  }
}

# subnet for NAT gateways / egress
resource "aws_subnet" "nat_subnet" {
  count                   = 3
  
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${100 + count.index}.0/24"
  map_public_ip_on_launch = false

  tags = {
    "Name" = "${var.project_name}-nat-subnet-${count.index}",
  }
}

# route table for nat subnets
resource "aws_route_table" "nat_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    "Name" = "${var.project_name}-nat-route-table",
  }
}

resource "aws_route_table_association" "nat_route_table_association" {
  count          = 3
  subnet_id      = aws_subnet.nat_subnet[count.index].id
  route_table_id = aws_route_table.nat_route_table.id
}

# place a NAT gateway in each of the NAT subnets
resource "aws_nat_gateway" "nat_gateway" {
  count         = 3
  allocation_id = var.elastic_ip_ids[count.index]
  subnet_id     = aws_subnet.nat_subnet[count.index].id

  tags = {
    "Name" = "${var.project_name}-nat-gateway-${count.index}",
  }
}

# subnets for EKS balancers
resource "aws_subnet" "balancer_subnet" {
  count = 3

  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${110 + count.index}.0/24"  
  map_public_ip_on_launch = false

  tags = {
    "Name" = "${var.project_name}-balancer-subnet-${count.index}",
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared",
    "kubernetes.io/role/elb" = 1
  }
}

# balancer subnets need direct egress to IGW work properly!
resource "aws_route_table" "balancer_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    "Name" = "${var.project_name}-balancer-route-table",
  }
}

resource "aws_route_table_association" "balancer_route_table_association" {
  count          = 3
  subnet_id      = aws_subnet.balancer_subnet[count.index].id
  route_table_id = aws_route_table.balancer_route_table.id
}

# subnets for internal nodes of the EKS cluster
resource "aws_subnet" "node_subnet" {
  count = 3

  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${120 + count.index}.0/24"  
  map_public_ip_on_launch = false

  tags = {
    "Name" = "${var.project_name}-node-subnet-${count.index}",
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared",
    "kubernetes.io/role/internal-elb" = 1
  }
}

# each of the node subnets routes out to the NAT gateway in the same AZ
resource "aws_route_table" "node_route_table" {
  count  = 3

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.nat_gateway[count.index].id
  }

  tags = {
    "Name" = "${var.project_name}-node-route-table-${count.index}",
  }
}

resource "aws_route_table_association" "node_route_table_association" {
  count          = 3
  subnet_id      = aws_subnet.node_subnet[count.index].id
  route_table_id = aws_route_table.node_route_table[count.index].id
}
