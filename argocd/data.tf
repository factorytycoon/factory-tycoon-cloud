data "aws_eks_cluster_auth" "eks" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state" 
    key    = "eks/terraform.tfstate"
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