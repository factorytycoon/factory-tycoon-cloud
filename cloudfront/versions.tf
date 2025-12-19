terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket       = "factory-tycoon-terraform-state2"
    key          = "cloudfront/terraform.tfstate"
    region       = "ap-northeast-2"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
