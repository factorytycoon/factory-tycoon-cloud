# ---------- IAM Policy (S3 Read for GLB) ----------
resource "aws_iam_policy" "aws_s3_read" {
  name = "sf-backend-aws-s3-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::factory-tycoon-frontend/*",
          "arn:aws:s3:::factory-tycoon/*"
        ]
      }
    ]
  })
}

# ---------- IAM Policy (Bedrock for AI) ----------
resource "aws_iam_policy" "aws_bedrock_access" {
  name        = "sf-backend-aws-bedrock-access"
  description = "Allow access to AWS Bedrock for AI features"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # "bedrock:InvokeModel",
          # "bedrock:InvokeModelWithResponseStream
          "bedrock:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# ---------- IRSA Role ----------
module "aws_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "sf-backend-aws-irsa"

  role_policy_arns = {
    s3      = aws_iam_policy.aws_s3_read.arn
    bedrock = aws_iam_policy.aws_bedrock_access.arn
  }

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["default:sf-backend-aws-sa"]
    }
  }
}
