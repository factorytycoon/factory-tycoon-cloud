provider "aws" {
  region  = var.aws_region
}

# EKS 클러스터 인증 정보 조회 (helm provider 초기화에 필요)
data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}

# Kubernetes Provider (선택적) - helm provider가 내부적으로 사용
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.eks.token
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

# Helm Provider (ALB Controller 설치에 사용)
provider "helm" {
  alias = "eks"

  kubernetes = {
    host                   = module.eks.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.eks.token
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  }
}
