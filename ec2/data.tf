# VPC 정보를 S3 Remote State에서 읽어옵니다
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state1"
    key    = "vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# 최신 Ubuntu 24.04 LTS AMI 검색
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
