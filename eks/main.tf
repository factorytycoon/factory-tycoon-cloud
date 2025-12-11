module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.34"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  cluster_endpoint_public_access = true

  enable_irsa = true

  cluster_addons = {
    coredns   = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni   = { most_recent = true }
  }

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

data "http" "alb_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.2/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = data.http.alb_iam_policy.body
}

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

module "aws_lb_controller" {
  source  = "terraform-aws-modules/helm/aws"
  version = "~> 1.0"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  chart      = "aws-load-balancer-controller"
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"

  values = [
    yamlencode({
      clusterName = module.eks.cluster_name
      region      = var.aws_region
      vpcId       = var.vpc_id
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.alb_irsa.iam_role_arn
        }
      }
    })
  ]
}
