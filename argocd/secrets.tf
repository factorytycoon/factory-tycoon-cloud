resource "kubernetes_secret_v1" "sf_backend_aws_secrets" {
  metadata {
    name      = "sf-backend-aws-secrets"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    # IRSA 사용으로 Access Key 제거
    # AWS_ACCESS_KEY = var.aws_aws_access_key_id
    # AWS_SECRET_KEY = var.aws_aws_secret_access_key
    AWS_BUCKET = var.aws_s3_bucket
    OPENSEARCH_ENDPOINT = data.terraform_remote_state.opensearch.outputs.endpoint
  }
}

resource "kubernetes_secret_v1" "sf_backend_secrets" {
  metadata {
    name      = "sf-backend-secrets"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    MARIADB_URL      = var.mariadb_url
    MARIADB_USERNAME = var.mariadb_username
    MARIADB_PASSWORD = var.mariadb_password
    REDIS_HOST       = data.terraform_remote_state.elasticache.outputs.redis_primary_endpoint
    JWT_SECRET_KEY   = var.jwt_secret_key
  }
}

resource "kubernetes_secret_v1" "sf_backend_websocket_secrets" {
  metadata {
    name      = "sf-backend-websocket-secrets"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    REDIS_HOST       = data.terraform_remote_state.elasticache.outputs.redis_primary_endpoint
    REDIS_STREAM_KEY = var.redis_stream_key
    CONSUMER_GROUP   = var.consumer_group
    CONSUMER_NAME    = var.consumer_name
  }
}
