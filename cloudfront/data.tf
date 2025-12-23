data "aws_s3_bucket" "frontend" {
  bucket = "factory-tycoon-frontend"
}

# EKS (ALB DNS 필요)
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "eks/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
