resource "kubernetes_secret" "sf_backend_glb_secrets" {
  metadata {
    name      = "sf-backend-glb-secrets"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    AWS_ACCESS_KEY = var.glb_aws_access_key_id
    AWS_SECRET_KEY = var.glb_aws_secret_access_key
    AWS_BUCKET     = var.glb_s3_bucket
  }
}

resource "kubernetes_secret" "sf_backend_secrets" {
  metadata {
    name      = "sf-backend-secrets"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    MARIADB_URL      = var.mariadb_url
    MARIADB_USERNAME = var.mariadb_username
    MARIADB_PASSWORD = var.mariadb_password
    REDIS_HOST       = var.redis_host
    JWT_SECRET_KEY   = var.jwt_secret_key
  }
}

resource "kubernetes_secret" "sf_backend_websocket_secrets" {
  metadata {
    name      = "sf-backend-sensor-secrets"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    REDIS_HOST       = var.redis_host
    REDIS_STREAM_KEY = var.redis_stream_key
    CONSUMER_GROUP   = var.consumer_group
    CONSUMER_NAME    = var.consumer_name
  }
}
