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
    REDIS_PASSWORD   = var.redis_password
    JWT_SECRET_KEY   = var.jwt_secret_key
  }
}
