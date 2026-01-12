# VPC 정보를 원격 상태에서 가져오기
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# Security Groups 정보를 원격 상태에서 가져오기
data "terraform_remote_state" "security_groups" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "security-groups/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# SNS 정보를 원격 상태에서 가져오기
data "terraform_remote_state" "sns" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "sns/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
# Lambda 정보를 원격 상태에서 가져오기
data "terraform_remote_state" "lambda" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "lambda/terraform.tfstate"
    region = "ap-northeast-2"
  }
}