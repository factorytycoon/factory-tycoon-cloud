provider "aws" {
  region  = var.aws_region
  profile = "edu"
}

# EKS 클러스터 정보 조회 (helm provider 초기화에 필요)
data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.cluster_name
}

# Kubernetes Provider (선택적) - helm provider가 내부적으로 사용
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  token                  = data.aws_eks_cluster_auth.eks.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
}

# Helm Provider (ALB Controller 설치에 사용)
provider "helm" {
  alias = "eks"

  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    token                  = data.aws_eks_cluster_auth.eks.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  }
}
