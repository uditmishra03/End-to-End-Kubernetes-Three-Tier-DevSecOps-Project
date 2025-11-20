# ECR Lifecycle Policies
# Automatically clean up untagged images older than 5 days while preserving all tagged images

# Lifecycle policy for frontend ECR repository
resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = "frontend"

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep all tagged images (no expiration)"
        selection = {
          tagStatus   = "tagged"
          tagPrefixList = ["20"] # Matches our date-based tags (YYYYMMDD-BUILD format)
          countType   = "imageCountMoreThan"
          countNumber = 9999 # Effectively unlimited
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 5 days (cache cleanup)"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Lifecycle policy for backend ECR repository
resource "aws_ecr_lifecycle_policy" "backend" {
  repository = "backend"

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep all tagged images (no expiration)"
        selection = {
          tagStatus   = "tagged"
          tagPrefixList = ["20"] # Matches our date-based tags (YYYYMMDD-BUILD format)
          countType   = "imageCountMoreThan"
          countNumber = 9999 # Effectively unlimited
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 5 days (cache cleanup)"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Output the policy details for verification
output "ecr_lifecycle_policies" {
  description = "ECR lifecycle policies applied to frontend and backend repositories"
  value = {
    frontend = {
      repository = aws_ecr_lifecycle_policy.frontend.repository
      policy_applied = "Untagged images deleted after 5 days, all tagged images preserved"
    }
    backend = {
      repository = aws_ecr_lifecycle_policy.backend.repository
      policy_applied = "Untagged images deleted after 5 days, all tagged images preserved"
    }
  }
}
