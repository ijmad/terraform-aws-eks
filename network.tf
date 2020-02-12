resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
  }
}

resource "aws_subnet" "subnet" {
  count = 3

  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.${count.index}.0/24"

  tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "route_table_association" {
  count = 3

  subnet_id      = aws_subnet.subnet.*.id[count.index]
  route_table_id = aws_route_table.route_table.id
}
