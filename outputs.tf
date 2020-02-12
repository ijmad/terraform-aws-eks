locals {
  aws_auth_local = <<-END
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: aws-auth
      namespace: kube-system
    data:
      mapRoles: |
        - rolearn: ${aws_iam_role.cluster_iam_role.arn}
          username: system:node:{{EC2PrivateDNSName}}
          groups:
            - system:bootstrappers
            - system:nodes
    END

  kubeconfig_local = <<-END
    apiVersion: v1
    clusters:
    - cluster:
        server: ${aws_eks_cluster.eks_cluster.endpoint}
        certificate-authority-data: ${aws_eks_cluster.eks_cluster.certificate_authority.0.data}
      name: kubernetes
    contexts:
    - context:
        cluster: kubernetes
        user: aws
      name: aws
    current-context: aws
    kind: Config
    preferences: {}
    users:
    - name: aws
      user:
        exec:
          apiVersion: client.authentication.k8s.io/v1alpha1
          command: aws-iam-authenticator
          args:
            - "token"
            - "-i"
            - "${var.project_name}-eks-cluster"
    END
}

output "aws_auth_output" {
  value = local.aws_auth_local
}

output "kubeconfig_output" {
  value = local.kubeconfig_local
}