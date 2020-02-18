# EFS for use with EKS as storage

resource "aws_efs_file_system" "efs_file_system" {
  creation_token = "${var.project_name}-efs-file-system"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = "true"

  tags = {
    name = "${var.project_name}-efs-file-system"
  }
}

resource "aws_security_group" "efs_security_group" {
  name        = "${var.project_name}-efs-security-group"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_efs_mount_target" "efs_mount_target" {
  count = 3

  file_system_id  = aws_efs_file_system.efs_file_system.id
  subnet_id       = aws_subnet.node_subnet.*.id[count.index]

  security_groups = [ 
    aws_security_group.efs_security_group.id 
  ]
}

# ingress from k8s
# define as a separate rule to avoid cycle

resource "aws_security_group_rule" "efs_security_group_k8s" {
  security_group_id        = aws_security_group.efs_security_group.id
  type                     = "ingress"
  protocol                 = "TCP"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}
