
data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  url = "https://oidc.eks.us-east-1.amazonaws.com/id/7D4C17F23AC420CA9AA2FE47EBEF25B1"
}

resource "aws_iam_policy" "argocd_image_updater_ecr_policy" {
  name        = "ArgoCDImageUpdaterECRAccess"
  description = "Allows ArgoCD Image Updater to access ECR for pulling image tags."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "argocd_image_updater_role" {
  name = "ArgoCDImageUpdaterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks_oidc_provider.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(data.aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")}:sub" = "system:serviceaccount:argocd:argocd-image-updater"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "argocd_image_updater_attach" {
  role       = aws_iam_role.argocd_image_updater_role.name
  policy_arn = aws_iam_policy.argocd_image_updater_ecr_policy.arn
}

output "argocd_image_updater_role_arn" {
  value = aws_iam_role.argocd_image_updater_role.arn
}
