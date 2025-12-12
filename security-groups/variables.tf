variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "factory-tycoon"
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default = {
    Project   = "factory-tycoon"
    ManagedBy = "terraform"
  }
}
