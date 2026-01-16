resource "kubernetes_config_map_v1" "sf_backend_config" {
  metadata {
    name      = "sf-backend-config"
    namespace = "default"
  }

  data = {
    JWT_ACCESS_TTL_MS  = var.jwt_access_ttl_ms
    JWT_REFRESH_TTL_MS = var.jwt_refresh_ttl_ms
    AWS_REGION         = var.aws_region
    REDIS_PORT         = var.backend_redis_port
    # Health check에서 mail 제외 (메일 인증 실패로 인한 pod 재시작 방지)
    MANAGEMENT_ENDPOINT_HEALTH_GROUP_READINESS_INCLUDE = "readinessState,db,redis"
    MANAGEMENT_HEALTH_MAIL_ENABLED                     = "false"
  }
}

resource "kubernetes_config_map_v1" "sf_backend_aws_config" {
  metadata {
    name      = "sf-backend-aws-config"
    namespace = "default"
  }

  data = {
    SERVER_PORT = var.aws_server_port
    AWS_REGION  = var.aws_region
  }
}

resource "kubernetes_config_map_v1" "sf_backend_websocket_config" {
  metadata {
    name      = "sf-backend-websocket-config"
    namespace = "default"
  }

  data = {
  }
}

