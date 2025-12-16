variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "bucket_name" {
  type        = string
  default     = "factory-tycoon-terraform-state3"
  description = "Terraform state를 저장할 S3 버킷 이름"
}

variable "project_name" {
  type    = string
  default = "ft"
}
