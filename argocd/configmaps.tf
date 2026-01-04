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

