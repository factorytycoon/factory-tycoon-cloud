
# 1. S3 버킷 - Terraform State 저장
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name
  force_destroy = true 

  tags = {
    Name    = var.bucket_name
    Project = var.project_name
    Purpose = "terraform-state"
  }
}

# 2. S3 버킷 버전 관리 활성화
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 3. S3 버킷 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. S3 버킷 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 5. 프로젝트 파일/모델링 파일용 S3 버킷
resource "aws_s3_bucket" "project_assets" {
  bucket        = var.assets_bucket_name
  force_destroy = true

  tags = {
    Name    = var.assets_bucket_name
    Project = var.project_name
    Purpose = "project-assets"
  }
}

# 6. 프로젝트 파일 S3 버킷 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "project_assets" {
  bucket = aws_s3_bucket.project_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 7. 프로젝트 파일 S3 버킷 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "project_assets" {
  bucket = aws_s3_bucket.project_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  project_assets_cors_rules = [
    {
      AllowedOrigins = ["https://factorytycoon.net"]
      AllowedMethods = ["*"]
      AllowedHeaders = ["*"]
      ExposeHeaders  = ["ETag"]
      MaxAgeSeconds  = 3000
    }
  ]
}

# 8. 프로젝트 파일 S3 버킷 CORS 설정
resource "aws_s3_bucket_cors_configuration" "project_assets" {
  bucket = aws_s3_bucket.project_assets.id

  dynamic "cors_rule" {
    for_each = local.project_assets_cors_rules
    content {
      allowed_headers = lookup(cors_rule.value, "AllowedHeaders", null)
      allowed_methods = lookup(cors_rule.value, "AllowedMethods", null)
      allowed_origins = lookup(cors_rule.value, "AllowedOrigins", null)
      expose_headers  = lookup(cors_rule.value, "ExposeHeaders", null)
      max_age_seconds = lookup(cors_rule.value, "MaxAgeSeconds", null)
    }
  }
}
