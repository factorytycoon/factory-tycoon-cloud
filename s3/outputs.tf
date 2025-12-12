output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "Terraform state S3 버킷 이름"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "Terraform state S3 버킷 ARN"
}

output "backend_config" {
  value = <<-EOT
    terraform {
      backend "s3" {
        bucket  = "${aws_s3_bucket.terraform_state.id}"
        key     = "<MODULE_NAME>/terraform.tfstate"
        region  = "${var.aws_region}"
        encrypt = true
      }
    }
  EOT
  description = "다른 모듈에서 사용할 backend 설정 예시"
}
