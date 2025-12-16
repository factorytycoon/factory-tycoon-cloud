provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.eks.token
  cluster_ca_certificate = base64decode(
    data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data
  )
}

provider "helm" {
  kubernetes = {
    host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.eks.token
    cluster_ca_certificate = base64decode(
      data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data
    )
  }
}
