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

data "terraform_remote_state" "elasticache" {
  backend = "s3"

  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "elasticache/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "opensearch" {
  backend = "s3"

  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "opensearch/terraform.tfstate"
    region = "ap-northeast-2"
  }
}