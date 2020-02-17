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

  subnet_id       = aws_subnet.prv_subnet.*.id[count.index]
  security_groups = [ aws_security_group.efs_security_group.id ]
  file_system_id  = aws_efs_file_system.efs_file_system.id
}

# ingress from k8s (can be pared down to just NFS port)
# define as a separate rule to avoid cycle

resource "aws_security_group_rule" "efs_security_group_k8s" {
  security_group_id        = aws_security_group.efs_security_group.id
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}
