variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project" {
  description = "프로젝트 이름"
  type        = string
  default     = "passorder"
}

variable "environment" {
  description = "환경 구분"
  type        = string
  default     = "dev"
}

variable "eks_node_instance_type" {
  description = "EKS 워커 노드 인스턴스 타입"
  type        = string
  default     = "t3.small"
}

variable "eks_node_desired" {
  description = "EKS 워커 노드 기본 개수"
  type        = number
  default     = 2
}

variable "eks_node_min" {
  description = "EKS 워커 노드 최소 개수"
  type        = number
  default     = 0
}

variable "eks_node_max" {
  description = "EKS 워커 노드 최대 개수"
  type        = number
  default     = 2
}