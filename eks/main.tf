module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.34"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  # kubectl 로컬 접근 허용
  cluster_endpoint_public_access = true

  # -------------------------------------------------------
  # 노드그룹 2개 구성
  # -------------------------------------------------------
  eks_managed_node_groups = {

    # FE / MQTT 노드그룹
    fe_group = {
      node_group_name = "fe-mqtt-nodegroup"
      instance_types  = ["t3.small"]
      desired_size    = 1
      min_size        = 1
      max_size        = 2
      capacity_type   = "ON_DEMAND"

      labels = {
        role = "frontend"
      }

      tags = {
        "Name" = "sf-node-fe"
      }
    }

    # BE 노드그룹
    be_group = {
      node_group_name = "backend-nodegroup"
      instance_types  = ["t3.small"]
      desired_size    = 1
      min_size        = 1
      max_size        = 2
      capacity_type   = "ON_DEMAND"

      labels = {
        role = "backend"
      }

      tags = {
        "Name" = "sf-node-be"
      }
    }
  }

  enable_cluster_creator_admin_permissions = true
}
