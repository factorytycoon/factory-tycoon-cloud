variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type    = string
  default = "ft"
  description = "프로젝트 이름 (리소스명 prefix)"
}

variable "devices" {
  type = map(object({
    thing_name   = string
    topic_prefix = string
    description  = string
  }))
  description = "IoT 디바이스 목록 (key는 디바이스 식별자)"
  default = {
    raspi1 = {
      thing_name   = "ft-pi-001"
      topic_prefix = "devices/ft/pi-001"
      description  = "라즈베리파이 1번"
    }
  }
}

variable "common_tags" {
  type = map(string)
  default = {
    Project = "factory-tycoon"
    Module  = "iot"
    Env     = "dev"
  }
}
