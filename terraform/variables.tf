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
  # t3.medium 사용 시도했으나 AWS 신규 계정 Free Tier 미지원으로 실패
  # aws ec2 describe-instance-types --filters "Name=free-tier-eligible,Values=true" 로 확인 후 t3.small 선택
}

variable "eks_node_desired" {
  default = 3
}

variable "eks_node_max" {
  default = 3
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