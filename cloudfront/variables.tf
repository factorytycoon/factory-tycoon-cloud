variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name created by EKS Ingress"
  default     = null
  nullable    = true
}

variable "ingress_name" {
  type        = string
  description = "Kubernetes Ingress name that provisions the ALB"
  default     = "factory-ingress"
}

variable "ingress_namespace" {
  type        = string
  description = "Kubernetes namespace for the Ingress"
  default     = "default"
}
