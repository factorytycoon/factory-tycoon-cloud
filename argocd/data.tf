data "aws_eks_cluster_auth" "eks" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state3" 
    key    = "eks/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
