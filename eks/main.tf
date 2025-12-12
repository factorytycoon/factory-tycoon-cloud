# EKS Cluster

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.34"

  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  cluster_endpoint_public_access = true

  # 공통 보안 그룹 추가
  cluster_additional_security_group_ids = [
    data.terraform_remote_state.security_groups.outputs.common_sg_id
  ]

  enable_irsa = true

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }
  
  create_cloudwatch_log_group = false

  eks_managed_node_groups = {
    fe_group = {
      node_group_name = "fe-mqtt-nodegroup"
      instance_types  = ["t3.small"]
      desired_size    = 1
      min_size        = 1
      max_size        = 2
      capacity_type   = "ON_DEMAND"
      labels = { role = "frontend" }
    }

    be_group = {
      node_group_name = "backend-nodegroup"
      instance_types  = ["t3.small"]
      desired_size    = 1
      min_size        = 1
      max_size        = 2
      capacity_type   = "ON_DEMAND"
      labels = { role = "backend" }
    }
  }

  enable_cluster_creator_admin_permissions = true
}


# IAM Policy for ALB Controller (AWS 공식 정책 다운로드)

data "http" "alb_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.2/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = data.http.alb_iam_policy.response_body
}


# IRSA for AWS Load Balancer Controller

module "alb_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "alb-controller-irsa"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}


# Helm — AWS Load Balancer Controller 설치

resource "helm_release" "aws_lb_controller" {
  provider   = helm.eks
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.1"
  namespace  = "kube-system"

  depends_on = [
    module.eks,
    module.alb_irsa
  ]

  values = [
  yamlencode({
    clusterName = module.eks.cluster_name
    region      = var.aws_region
    vpcId       = data.terraform_remote_state.vpc.outputs.vpc_id

    serviceAccount = {
      create = true
      annotations = {
        "eks.amazonaws.com/role-arn" = module.alb_irsa.iam_role_arn
      }
    }
  })
]
}
