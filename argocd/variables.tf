variable "github_username" {
  description = "GitHub username for ArgoCD repo access"
  type        = string
}

variable "github_pat" {
  description = "GitHub personal access token for ArgoCD"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "glb_aws_access_key_id" {
  type      = string
  sensitive = true
}

variable "glb_aws_secret_access_key" {
  type      = string
  sensitive = true
}

variable "glb_s3_bucket" {
  type = string
}