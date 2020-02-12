resource "aws_iam_role" "node_iam_role" {
  name               = "${var.project_name}-node-iam-role"
  assume_role_policy = <<-END
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
    END
}

resource "aws_iam_role_policy_attachment" "worker_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "cni_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "ecrro_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_iam_role.name
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.project_name}-eks-node-group"
  node_role_arn   = aws_iam_role.node_iam_role.arn
  subnet_ids      = aws_subnet.subnet[*].id

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["t1.micro"]

  depends_on = [
    aws_iam_role_policy_attachment.worker_role_policy_attachment,
    aws_iam_role_policy_attachment.cni_role_policy_attachment,
    aws_iam_role_policy_attachment.ecrro_role_policy_attachment,
  ]
}