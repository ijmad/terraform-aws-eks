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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.project_name}-eks-cluster"
  role_arn = aws_iam_role.cluster_iam_role.arn

  vpc_config {
    security_group_ids = [aws_security_group.security_group.id]
    subnet_ids         = aws_subnet.subnet[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_iam_role_policy_attachment,
    aws_iam_role_policy_attachment.service_iam_role_policy_attachment,
  ]
}
