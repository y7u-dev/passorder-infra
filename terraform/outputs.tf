output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "EKS 클러스터 이름"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS 클러스터 엔드포인트"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  description = "ECR 레포지토리 URL"
  value       = aws_ecr_repository.passorder.repository_url
}