variable "project" {
  description = "Project name"
  type        = string
  default     = "factory-tycoon"
}

variable "redis_endpoint_local" {
  description = "ElastiCache Redis endpoint"
  type        = string
  default     = "localhost"
}

variable "redis_port_local" {
  description = "ElastiCache Redis port"
  type        = number
  default     = 6379
}
variable "redis_password_local" {
  description = "ElastiCache Redis password"
  type        = string
  default     = "password"
}

variable "mongodb_uri" {
  description = "MongoDB connection URI"
  type        = string
  sensitive   = true
}

variable "mongodb_database" {
  description = "MongoDB database name"
  type        = string
  default     = "factory-tycoon"
}

variable "mariadb_host" {
  description = "host for MariaDB"
  type        = string
}

variable "mariadb_port" {
  description = "port for MariaDB"
  default     = 3306
  type        = number
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

# variable "opensearch_endpoint" {
#   description = "OpenSearch endpoint URL"
#   type        = string
# }

variable "iot_topic" {
  description = "IoT topic to subscribe"
  type        = string
  default     = "sensor/data/#"
}
