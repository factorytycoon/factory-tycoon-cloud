# ---------- Data Sources ----------
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

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

# ---------- IAM Policy (AWS Marketplace for Bedrock models) ----------
resource "aws_iam_policy" "aws_marketplace_access" {
  name        = "sf-backend-aws-marketplace-access"
  description = "Allow AWS Marketplace subscription checks for Bedrock models"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aws-marketplace:ViewSubscriptions",
          "aws-marketplace:Subscribe"
        ]
        Resource = "*"
      }
    ]
  })
}

# ---------- IAM Policy (OpenSearch Access) ----------
resource "aws_iam_policy" "aws_opensearch_access" {
  name        = "sf-backend-aws-opensearch-access"
  description = "Allow access to AWS OpenSearch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "es:*"
        ]
        Resource = "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/factory-tycoon-search/*"
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
    s3         = aws_iam_policy.aws_s3_read.arn
    bedrock    = aws_iam_policy.aws_bedrock_access.arn
    marketplace = aws_iam_policy.aws_marketplace_access.arn
    opensearch = aws_iam_policy.aws_opensearch_access.arn
  }

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["default:sf-backend-aws-sa"]
    }
  }
}
