variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "topic_name" {
  description = "SNS Topic name"
  type        = string
  default     = "factory-tycoon-events"
}

variable "kms_master_key_id" {
  description = "Optional KMS CMK ARN or ID for topic encryption"
  type        = string
  default     = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    Project     = "factory-tycoon"
    ManagedBy   = "terraform"
    Environment = "production"
  }
}
