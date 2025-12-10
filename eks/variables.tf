variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}
