resource "kubernetes_secret" "glb_aws_secret" {
  metadata {
    name      = "glb-aws-secret"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    AWS_ACCESS_KEY_ID     = var.glb_aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.glb_aws_secret_access_key
    AWS_BUCKET            = var.glb_s3_bucket
  }
}
