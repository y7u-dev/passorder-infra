resource "aws_ecr_repository" "passorder" {
  name                 = "${var.project}-api"
  image_tag_mutability = "MUTABLE"

  # 보안: 이미지 취약점 스캔 활성화
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-api"
  }
}

# 이미지 수명 주기 정책 (오래된 이미지 자동 삭제 → 비용 절감)
resource "aws_ecr_lifecycle_policy" "passorder" {
  repository = aws_ecr_repository.passorder.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "최근 10개 이미지만 유지"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}