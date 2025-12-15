variable "project" {
  description = "Project name"
  type        = string
  default     = "factory-tycoon"
}

# variable "redis_endpoint" {
#   description = "ElastiCache Redis endpoint"
#   type        = string
#   default     = data.terraform_remote_state.elasticache.outputs.redis_primary_endpoint
# }

# variable "redis_port" {
#   description = "ElastiCache Redis port"
#   type        = number
#   default     = 6379
# }

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

# variable "opensearch_endpoint" {
#   description = "OpenSearch endpoint URL"
#   type        = string
# }

variable "iot_topic" {
  description = "IoT topic to subscribe"
  type        = string
  default     = "sensor/data/#"
}
