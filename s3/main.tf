
# 1. S3 버킷 - Terraform State 저장
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name
  force_destroy = true  # destroy 시 버킷 내 모든 객체 자동 삭제

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
