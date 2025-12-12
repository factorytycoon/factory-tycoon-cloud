variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type    = string
  default = "ft"
  description = "프로젝트 이름 (리소스명 prefix)"
}

variable "instance_type" {
  type    = string
  default = "t3.large"
  description = "EC2 인스턴스 타입"
}

variable "key_name" {
  type        = string
  default     = "mw_key"
  description = "SSH 키페어 이름 (사전 생성 필요)"
}

variable "instance_name" {
  type    = string
  default = "ft-server"
  description = "EC2 인스턴스 이름"
}

variable "root_volume_size" {
  type    = number
  default = 30
  description = "루트 볼륨 크기 (GB)"
}

variable "allowed_ssh_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "SSH 접근 허용 CIDR (보안을 위해 특정 IP로 제한 권장)"
}

variable "common_tags" {
  type = map(string)
  default = {
    Project = "factory-tycoon"
    Module  = "ec2"
    Env     = "dev"
  }
}
