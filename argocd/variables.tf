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

# ---------- GLB Secrets ----------
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

# ---------- Backend Secrets ----------
variable "mariadb_url" {
  description = "JDBC URL for MariaDB"
  type        = string
}

variable "mariadb_username" {
  description = "Username for MariaDB"
  type        = string
}

variable "mariadb_password" {
  description = "Password for MariaDB"
  type        = string
  sensitive   = true
}

variable "redis_host" {
  description = "Host address for Redis"
  type        = string
}

variable "redis_password" {
  description = "Password for Redis"
  type        = string
  default     = ""
  sensitive   = true
}

variable "jwt_secret_key" {
  description = "Secret key for JWT"
  type        = string
  sensitive   = true
}

# ---------- Backend Configs ----------
variable "jwt_access_ttl_ms" {
  type    = string
  default = "3600000"
}

variable "jwt_refresh_ttl_ms" {
  type    = string
  default = "86400000"
}

variable "backend_redis_port" {
  type    = string
  default = "6379"
}

# ---------- GLB Configs ----------
variable "glb_server_port" {
  type    = string
  default = "8081"
}

# ---------- Redis Stream Configs ----------
variable "redis_stream_key" {
  description = "Redis stream key for backend consumer"
  type        = string
}

variable "consumer_group" {
  description = "Redis consumer group name"
  type        = string
}

variable "consumer_name" {
  description = "Redis consumer name"
  type        = string
}