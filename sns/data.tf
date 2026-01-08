# Reference to Lambda functions
data "terraform_remote_state" "lambda" {
  backend = "s3"

  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "lambda/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
