data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "factory-tycoon-terraform-state3"
    key    = "vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "security_groups" {
  backend = "s3"

  config = {
    bucket = "factory-tycoon-terraform-state3"
    key    = "security-groups/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "elasticache" {
  backend = "s3"

  config = {
    bucket = "factory-tycoon-terraform-state3"
    key    = "elasticache/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "opensearch" {
  backend = "s3"

  config = {
    bucket = "factory-tycoon-terraform-state3"
    key    = "opensearch/terraform.tfstate"
    region = "ap-northeast-2"
  }
}