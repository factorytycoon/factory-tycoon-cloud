terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "factory-tycoon-terraform-state3"
    key    = "security-groups/terraform.tfstate"
    region = "ap-northeast-2"
    use_lockfile = true
  }
}
