# VPC 정보를 S3 Remote State에서 읽어옵니다.
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state3"
    key    = "vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# Security Groups 정보를 S3 Remote State에서 읽어옵니다.
data "terraform_remote_state" "security_groups" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state3"
    key    = "security-groups/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
