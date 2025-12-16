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