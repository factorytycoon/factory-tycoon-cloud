# ---------- IAM Policy (S3 Read for GLB) ----------
resource "aws_iam_policy" "glb_s3_read" {
  name = "sf-backend-glb-s3-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::factory-tycoon-frontend/*"
      }
    ]
  })
}

# ---------- IRSA Role ----------
module "glb_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "sf-backend-glb-irsa"

  role_policy_arns = {
    s3 = aws_iam_policy.glb_s3_read.arn
  }

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["default:sf-backend-glb-sa"]
    }
  }
}
