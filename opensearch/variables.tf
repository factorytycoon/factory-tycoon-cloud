variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "domain_name" {
  description = "OpenSearch 도메인 이름"
  type        = string
  default     = "factory-tycoon-search"
}

variable "instance_type" {
  description = "OpenSearch 인스턴스 타입"
  type        = string
  default     = "t3.small.search"
}

variable "instance_count" {
  description = "OpenSearch 인스턴스 개수"
  type        = number
  default     = 1
}

variable "ebs_volume_size" {
  description = "EBS 볼륨 크기 (GB)"
  type        = number
  default     = 10
}

variable "master_user_name" {
  description = "마스터 사용자 이름"
  type        = string
  default     = "user"
}

variable "master_user_password" {
  description = "마스터 사용자 패스워드"
  type        = string
  sensitive   = true
  default     = "12345678"
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default = {
    Project = "factory-tycoon"
  }
}
