# OpenSearch 도메인
resource "aws_opensearch_domain" "main" {
  domain_name    = var.domain_name
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type  = var.instance_type
    instance_count = var.instance_count
    
    # 단일 AZ 구성
    zone_awareness_enabled = false
  }

  # VPC 구성
  vpc_options {
    subnet_ids = [data.terraform_remote_state.vpc.outputs.private_subnets[0]]
    security_group_ids = [
      data.terraform_remote_state.security_groups.outputs.common_sg_id,
      data.terraform_remote_state.security_groups.outputs.data_sg_id
    ]
  }

  # EBS 스토리지
  ebs_options {
    ebs_enabled = true
    volume_size = var.ebs_volume_size
    volume_type = "gp3"
  }

  # 마스터 사용자 인증
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = var.master_user_name
      master_user_password = var.master_user_password
    }
  }

  # 전송 중 암호화
  encrypt_at_rest {
    enabled = true
  }

  # 노드 간 암호화
  node_to_node_encryption {
    enabled = true
  }

  # 도메인 엔드포인트 옵션
  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  # 액세스 정책 (VPC 내부에서만 접근)
  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "es:*"
        Resource = "arn:aws:es:${var.region}:*:domain/${var.domain_name}/*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = var.domain_name
    }
  )
}
