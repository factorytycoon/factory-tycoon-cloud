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

locals {
  eks_cluster_name = data.terraform_remote_state.eks.outputs.cluster_name
  cluster_tag_key  = format("kubernetes.io/cluster/%s", local.eks_cluster_name)
  ingress_stack    = format("%s/%s", var.ingress_namespace, var.ingress_name)
}

data "aws_lbs" "factory_ingress_by_k8s_tags" {
  tags = {
    (local.cluster_tag_key)      = "owned"
    "kubernetes.io/namespace"    = var.ingress_namespace
    "kubernetes.io/ingress-name" = var.ingress_name
  }
}

data "aws_lbs" "factory_ingress_by_k8s_tags_shared" {
  tags = {
    (local.cluster_tag_key)      = "shared"
    "kubernetes.io/namespace"    = var.ingress_namespace
    "kubernetes.io/ingress-name" = var.ingress_name
  }
}

data "aws_lbs" "factory_ingress_by_controller_tags" {
  tags = {
    "elbv2.k8s.aws/cluster"  = local.eks_cluster_name
    "ingress.k8s.aws/stack"  = local.ingress_stack
  }
}

locals {
  factory_ingress_lb_arns = distinct(
    concat(
      tolist(data.aws_lbs.factory_ingress_by_k8s_tags.arns),
      tolist(data.aws_lbs.factory_ingress_by_k8s_tags_shared.arns),
      tolist(data.aws_lbs.factory_ingress_by_controller_tags.arns)
    )
  )

  factory_ingress_lb_arn = length(local.factory_ingress_lb_arns) == 1 ? local.factory_ingress_lb_arns[0] : null
}

data "aws_lb" "factory_ingress" {
  count = local.factory_ingress_lb_arn == null ? 0 : 1
  arn   = local.factory_ingress_lb_arn
}

locals {
  alb_dns_name = try(coalesce(var.alb_dns_name, data.aws_lb.factory_ingress[0].dns_name), null)
}
