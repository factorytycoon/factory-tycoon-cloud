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
  default     = "t3.medium.search"
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
  default     = "12345678Qq!"
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default = {
    Project = "factory-tycoon"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
# ============================================================================
# Monitoring Trigger Configuration
# ============================================================================

# Inspection Process Sensor Thresholds
variable "inspection_config" {
  description = "Inspection (검수) 공정 센서 임계값"
  type = object({
    weight_red_low     = number
    weight_red_high    = number
    weight_yellow_low  = number
    weight_yellow_high = number
    
    torque_red_low     = number
    torque_red_high    = number
    torque_orange_low  = number
    torque_orange_high = number
    torque_yellow_low  = number
    torque_yellow_high = number
  })
  default = {
    weight_red_low     = 400
    weight_red_high    = 1700
    weight_yellow_low  = 400
    weight_yellow_high = 1700
    
    torque_red_low     = 5
    torque_red_high    = 55
    torque_orange_low  = 46
    torque_orange_high = 55
    torque_yellow_low  = 30
    torque_yellow_high = 45
  }
}

# Painting Process Sensor Thresholds
variable "painting_config" {
  description = "Painting (도색) 공정 센서 임계값"
  type = object({
    voc_red        = number
    voc_orange_low = number
    voc_orange_high = number
    voc_yellow_low = number
    voc_yellow_high = number
    
    pressure_red_low    = number
    pressure_red_high   = number
    pressure_orange_low = number
    pressure_orange_high = number
    pressure_yellow_low = number
    pressure_yellow_high = number
    
    temp_red            = number
    temp_orange_low     = number
    temp_orange_high    = number
    temp_yellow_low     = number
    temp_yellow_high    = number
  })
  default = {
    voc_red         = 500
    voc_orange_low  = 150
    voc_orange_high = 499
    voc_yellow_low  = 50
    voc_yellow_high = 149
    
    pressure_red_low     = 1.0
    pressure_red_high    = 7.0
    pressure_orange_low  = 3.5
    pressure_orange_high = 4.8
    pressure_yellow_low  = 3.5
    pressure_yellow_high = 4.8
    
    temp_red            = 80
    temp_orange_low     = 38
    temp_orange_high    = 55
    temp_yellow_low     = 38
    temp_yellow_high    = 55
  }
}

# Turning Process Sensor Thresholds
variable "turning_config" {
  description = "Turning (선삭) 공정 센서 임계값"
  type = object({
    rpm_red_low     = number
    rpm_orange_low  = number
    rpm_orange_high = number
    rpm_yellow_low  = number
    rpm_yellow_high = number
    rpm_orange_high2 = number
    
    noise_red           = number
    noise_orange_low    = number
    noise_orange_high   = number
    noise_yellow_low    = number
    noise_yellow_high   = number
    
    displacement_red    = number
    displacement_orange_low = number
    displacement_orange_high = number
    displacement_yellow_low = number
    displacement_yellow_high = number
  })
  default = {
    rpm_red_low     = 500
    rpm_orange_low  = 2400
    rpm_orange_high = 2699
    rpm_yellow_low  = 2700
    rpm_yellow_high = 2899
    rpm_orange_high2 = 3300
    
    noise_red           = 115
    noise_orange_low    = 106
    noise_orange_high   = 114
    noise_yellow_low    = 99
    noise_yellow_high   = 105
    
    displacement_red         = 1.00
    displacement_orange_low  = 0.51
    displacement_orange_high = 1.00
    displacement_yellow_low  = 0.21
    displacement_yellow_high = 0.50
  }
}

# Alert Severity Thresholds (by total score)
variable "alert_thresholds" {
  description = "알람 레벨별 총점 임계값"
  type = object({
    yellow_min = number
    yellow_max = number
    orange_min = number
    orange_max = number
    red_min    = number
  })
  default = {
    yellow_min = 6
    yellow_max = 6
    orange_min = 7
    orange_max = 9
    red_min    = 10
  }
}

# SNS Topic ARN for Alerts
variable "sns_topic_arn" {
  description = "SNS Topic ARN for sending alerts"
  type        = string
  default     = ""  # Will be retrieved from data.terraform_remote_state if empty
}

# Lambda Function ARN for Processing Alerts
variable "lambda_function_arn" {
  description = "Lambda Function ARN for processing opensearch alerts"
  type        = string
  default     = ""  # Will be retrieved from data.terraform_remote_state if empty
}