# EFS for use with EKS as storage

resource "aws_security_group" "efs_security_group" {
  name        = "${var.project_name}-efs-security-group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = aws_subnet.prv_subnet[*].cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = aws_subnet.prv_subnet[*].cidr_block
  }
}

resource "aws_efs_file_system" "efs_file_system" {
  creation_token = "${var.project_name}-efs-file-system"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = "true"

  tags = {
    name = "${var.project_name}-efs-file-system"
  }
}

resource "aws_subnet" "efs_subnet" {
  count = 3

  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index + 50}.0/24"  
  map_public_ip_on_launch = false

  tags = {
    "name" = "${var.project_name}-efs-subnet-${count.index}"
  }
}

resource "aws_efs_mount_target" "alpha" {
  count = 3

  file_system_id = aws_efs_file_system.efs_file_system.id
  subnet_id      = aws_subnet.efs_subnet.*.id[count.index]
}
