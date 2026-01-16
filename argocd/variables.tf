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

# ---------- AWS Secrets ----------
variable "aws_aws_access_key_id" {
  type      = string
  default   = null
  sensitive = true
}

variable "aws_aws_secret_access_key" {
  type      = string
  default   = null
  sensitive = true
}

variable "aws_s3_bucket" {
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

# variable "redis_host" {
#   description = "Host address for Redis"
#   type        = string
# }

# variable "redis_password" {
#   description = "Password for Redis"
#   type        = string
#   default     = ""
#   sensitive   = true
# }

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

# ---------- AWS Configs ----------
variable "aws_server_port" {
  type    = string
  default = "8081"
}

# ---------- Redis Configs ----------
variable "redis_channel" {
  description = "Redis pubsub channel for sensor data"
  type        = string
  default     = "sensor_data"
}

variable "websocket_path" {
  description = "WebSocket endpoint path"
  type        = string
  default     = "/ws"
}

variable "spring_mail_host" {
  description = "SMTP host for Spring Mail"
  type        = string
}

variable "spring_mail_username" {
  description = "SMTP username for Spring Mail"
  type        = string
}

variable "spring_mail_password" {
  description = "SMTP password for Spring Mail"
  type        = string
  sensitive   = true
}