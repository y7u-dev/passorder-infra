module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project}-cluster"
  cluster_version = "1.31"

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS 관리형 노드 그룹
  eks_managed_node_groups = {
    spot = {
      name           = "${var.project}-spot-ng"
      instance_types = [var.eks_node_instance_type]

      min_size     = var.eks_node_min
      max_size     = var.eks_node_max
      desired_size = var.eks_node_desired

      # Spot Instance 설정
      capacity_type = "SPOT"

      labels = {
        Environment = var.environment
        Project     = var.project
      }
    }
  }

  # kubectl 접근 허용
  enable_cluster_creator_admin_permissions = true
}