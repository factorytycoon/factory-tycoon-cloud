terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "factory-tycoon-terraform-state"
    key            = "iot/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    use_lockfile   = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
