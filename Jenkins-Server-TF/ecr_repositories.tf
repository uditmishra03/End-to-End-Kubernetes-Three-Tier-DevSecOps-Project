# ECR Repositories
# Define ECR repositories for frontend and backend container images

resource "aws_ecr_repository" "frontend" {
  name                 = "frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "Frontend ECR Repository"
    Project     = "Three-Tier-DevSecOps"
    ManagedBy   = "Terraform"
    Environment = "Production"
  }
}

resource "aws_ecr_repository" "backend" {
  name                 = "backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "Backend ECR Repository"
    Project     = "Three-Tier-DevSecOps"
    ManagedBy   = "Terraform"
    Environment = "Production"
  }
}

# Outputs for easy reference
output "ecr_repository_urls" {
  description = "ECR repository URLs for frontend and backend"
  value = {
    frontend = aws_ecr_repository.frontend.repository_url
    backend  = aws_ecr_repository.backend.repository_url
  }
}

output "ecr_repository_arns" {
  description = "ECR repository ARNs for IAM policies"
  value = {
    frontend = aws_ecr_repository.frontend.arn
    backend  = aws_ecr_repository.backend.arn
  }
}
