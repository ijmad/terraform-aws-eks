# create auth for uploading to the ECR repos
# resource "random_id" "ecr_username" {
#   byte_length = 8
# }

# resource "aws_iam_user" "ecr_iam_user" {
#   name = "${var.project_name}-ecr-user-${random_id.ecr_username.hex}"
# }

# resource "aws_iam_access_key" "ecr_key" {
#   user = aws_iam_user.ecr_iam_user.name
# }

# data "aws_iam_policy_document" "ecr_policy" {
#   statement {
#     actions = [
#       "ecr:CompleteLayerUpload",
#       "ecr:BatchDeleteImage",
#       "ecr:UploadLayerPart",
#       "ecr:InitiateLayerUpload",
#       "ecr:PutImage",
#     ]

#     resources = [
#       "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*",
#     ]
#   }
# }

# resource "aws_iam_user_policy" "ecr_policy" {
#   name   = "${var.project_name}-ecr-writer"
#   policy = data.aws_iam_policy_document.ecr_policy.json
#   user   = aws_iam_user.ecr_iam_user.name
# }

# creates repositories for the CSI images to live inside our ECR
# these can't be fetched from outside the VPN once the security group rules are in place

resource "aws_ecr_repository" "registrar_ecr_repository" {
  name                 = "${var.project_name}/csi/registrar"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  # provisioner "local-exec" {
  #   command = <<-END_SCRIPT
  #     aws ecr get-login --no-include-email
  #     END_SCRIPT

  #   interpreter = ["/bin/bash", "-c"]

  #   environment = {
  #     AWS_ACCESS_KEY_ID = aws_iam_access_key.ecr_key.id
  #     AWS_SECRET_ACCESS_KEY = aws_iam_access_key.ecr_key.secret
  #   }
  # }
}

resource "aws_ecr_repository" "driver_ecr_repository" {
  name                 = "${var.project_name}/csi/driver"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_repository" "livenessprobe_ecr_repository" {
  name                 = "${var.project_name}/csi/livenessprobe"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}


locals {
  # # a series of docker commands to run that move images to the private ECR registry

  # csi_docker_script = <<-END
  #   docker pull amazon/aws-efs-csi-driver
  #   docker tag
  #   docker push ${aws_ecr_repository.driver_ecr_repository.repository_url}:v0.2.0

  #   docker pull quay.io/k8scsi/livenessprobe
  #   docker tag
  #   docker push ${aws_ecr_repository.livenessprobe_ecr_repository.repository_url}:v1.1.0

  #   docker pull quay.io/k8scsi/csi-node-driver-registrar
  #   docker tag
  #   docker push ${aws_ecr_repository.registrar_ecr_repository.repository_url}:v1.1.0
  # END

  # outputs the kustomization that loads the CSI driver from ECR
  # it needs to be applied with kubectl -k 

  # csi_kustomization_local = <<-END
  #   apiVersion: kustomize.config.k8s.io/v1beta1
  #   kind: Kustomization
  #   bases:
  #   - https://github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/base/?ref=master
  #   images:
  #   - name: amazon/aws-efs-csi-driver
  #     newName: ${aws_ecr_repository.driver_ecr_repository.repository_url}
  #     newTag: v0.2.0
  #   - name: quay.io/k8scsi/livenessprobe
  #     newName: ${aws_ecr_repository.livenessprobe_ecr_repository.repository_url}
  #     newTag: v1.1.0
  #   - name: quay.io/k8scsi/csi-node-driver-registrar
  #     newName: ${aws_ecr_repository.registrar_ecr_repository.repository_url}
  #     newTag: v1.1.0
  #   END
}

# output "csi_kustomization_output" {
#   value = local.csi_kustomization_local
# }
