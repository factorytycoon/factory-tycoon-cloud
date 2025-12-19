# VPC 정보를 원격 상태에서 가져오기
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state2"
    key    = "vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
