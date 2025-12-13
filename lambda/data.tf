data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "security_groups" {
  backend = "s3"

  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "security-groups/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
