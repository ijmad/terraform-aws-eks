# create secure endpoints inside the VPC to access certain services

# ECR
resource "aws_vpc_endpoint" "ecr_dkr_vpc_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  vpc_endpoint_type   = "Interface"

  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  private_dns_enabled = true

  subnet_ids          = aws_subnet.node_subnet.*.id
  security_group_ids  = [
    aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  ]

  tags = {
    "Name" = "${var.project_name}-ecr-dkr-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_api_vpc_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  vpc_endpoint_type   = "Interface"

  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  private_dns_enabled = true

  subnet_ids          = aws_subnet.node_subnet.*.id
  security_group_ids  = [
      aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  ]

  tags = {
    "Name" = "${var.project_name}-ecr-api-vpc-endpoint"
  }
}

# S3 (required for ECR)
resource "aws_vpc_endpoint" "s3_vpc_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  vpc_endpoint_type   = "Gateway"
  
  service_name        = "com.amazonaws.${data.aws_region.current.name}.s3"
  route_table_ids     = aws_route_table.node_route_table.*.id

  tags = {
    "Name" = "${var.project_name}-s3-vpc-endpoint"
  }
}