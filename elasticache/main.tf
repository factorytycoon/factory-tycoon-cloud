# ==========================================
# ElastiCache Redis (VPC 내부, Private Subnet)
# ==========================================

# 1. Security Group - Redis 접근 제어
resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  ingress {
    description = "Redis from VPC"
    from_port   = var.redis_port
    to_port     = var.redis_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-redis-sg"
    }
  )
}

# 2. Subnet Group - Redis가 배치될 서브넷
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = var.private_subnets

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-redis-subnet-group"
    }
  )
}

# 3. Parameter Group - Redis 설정
resource "aws_elasticache_parameter_group" "redis" {
  name   = "${var.project_name}-redis-params"
  family = var.redis_parameter_group_family

  # 필요시 파라미터 추가
  # parameter {
  #   name  = "maxmemory-policy"
  #   value = "allkeys-lru"
  # }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-redis-params"
    }
  )
}

# 4. Redis Replication Group (Cluster Mode Disabled)
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.project_name}-redis"
  description                = "Redis cluster for Factory Tycoon"
  engine                     = "redis"
  engine_version             = var.redis_engine_version
  node_type                  = var.redis_node_type
  num_cache_clusters         = var.redis_num_cache_nodes
  port                       = var.redis_port
  parameter_group_name       = aws_elasticache_parameter_group.redis.name
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  automatic_failover_enabled = var.redis_num_cache_nodes > 1 ? true : false
  multi_az_enabled           = var.redis_num_cache_nodes > 1 ? true : false

  # 암호화 (선택사항, 비용 고려)
  at_rest_encryption_enabled = false
  transit_encryption_enabled = false

  # 백업 설정
  snapshot_retention_limit = 1
  snapshot_window          = "03:00-05:00"
  maintenance_window       = "sun:05:00-sun:07:00"

  # 자동 업그레이드
  auto_minor_version_upgrade = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-redis"
    }
  )
}
