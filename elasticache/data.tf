# VPC 정보를 S3 Remote State에서 가져오기
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
