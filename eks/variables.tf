variable "cluster_name" {
  type = string
  default = "factory-tycoon-eks"
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}