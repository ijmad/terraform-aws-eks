resource "aws_iam_role" "cluster_iam_role" {
  name               = "${var.project_name}-cluster-iam-role"
  assume_role_policy = <<-END
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "eks.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
    END
}

resource "aws_iam_role_policy_attachment" "cluster_iam_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_iam_role.name
}

resource "aws_iam_role_policy_attachment" "service_iam_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster_iam_role.name
}

resource "aws_security_group" "security_group" {
  name        = "${var.project_name}-security-group"
  vpc_id      = aws_vpc.vpc.id

  # egress to public subnet for nat gateway

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [ aws_subnet.pub_subnet.cidr_block ] 
  }

  # egress to EFS

  egress {
    protocol        = "TCP"
    from_port       = 2049
    to_port         = 2049
    security_groups = [ aws_security_group.efs_security_group.id ]
  }
}

resource "aws_eks_cluster" "eks_cluster" {
  name                      = "${var.project_name}-eks-cluster"
  role_arn                  = aws_iam_role.cluster_iam_role.arn
  enabled_cluster_log_types = ["api", "controllerManager", "scheduler"]

  vpc_config {
    security_group_ids = [
      aws_security_group.security_group.id
    ]

    subnet_ids         = aws_subnet.prv_subnet[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_iam_role_policy_attachment,
    aws_iam_role_policy_attachment.service_iam_role_policy_attachment,
  ]
}

# tighten up rules on created security group
# still need to remove the 0.0.0.0/0 rule created automatically

# rule for self
resource "aws_security_group_rule" "eks_created_self_security_group_rule" {
  security_group_id        = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  type                     = "egress"
  protocol                 = -1
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

# rule for control plane group
resource "aws_security_group_rule" "eks_created_cp_security_group_rule" {
  security_group_id        = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  type                     = "egress"
  protocol                 = -1
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_security_group.security_group.id
}

# rule for efs
resource "aws_security_group_rule" "eks_created_efs_security_group_rule" {
  security_group_id        = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  type                     = "egress"
  protocol                 = "TCP"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.efs_security_group.id
}