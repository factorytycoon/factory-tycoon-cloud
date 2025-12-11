variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type    = string
  default = "ft"
  description = "프로젝트 이름 (리소스명 prefix)"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "Redis 접근 허용 CIDR (VPC CIDR)"
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro"
  description = "Redis 노드 타입"
}

variable "redis_num_cache_nodes" {
  type    = number
  default = 1
  description = "Redis 노드 개수 (1=단일, 2+=replication)"
}

variable "redis_engine_version" {
  type    = string
  default = "7.2"
  description = "Valkey 엔진 버전 (7.2+)"
}

variable "redis_parameter_group_family" {
  type    = string
  default = "valkey7"
  description = "Valkey 파라미터 그룹 패밀리"
}

variable "redis_port" {
  type    = number
  default = 6379
  description = "Redis 포트"
}

variable "common_tags" {
  type = map(string)
  default = {
    Project = "factory-tycoon"
    Module  = "elasticache"
    Env     = "dev"
  }
}
