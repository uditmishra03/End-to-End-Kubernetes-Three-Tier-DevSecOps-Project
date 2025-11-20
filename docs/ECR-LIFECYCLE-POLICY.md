# ECR Lifecycle Policy Management

## Overview
This document describes the ECR lifecycle policies implemented to automatically clean up untagged images (Docker cache layers) while preserving all tagged production images.

## Policy Details

### Frontend Repository (`frontend`)
- **Tagged Images:** Preserved indefinitely (no limit)
- **Untagged Images:** Deleted after 5 days
- **Rationale:** Removes intermediate Docker build cache layers while keeping all deployable images

### Backend Repository (`backend`)
- **Tagged Images:** Preserved indefinitely (no limit)
- **Untagged Images:** Deleted after 5 days
- **Rationale:** Removes intermediate Docker build cache layers while keeping all deployable images

## What Gets Deleted?

**Untagged Images (Cache Layers):**
- BuildKit cache layers
- Intermediate build stages
- Abandoned multi-architecture images
- Age: Older than 5 days

**Example from your ECR:**
```
- (untagged image)  0.00 MB   ← Will be deleted after 5 days
- (untagged image)  0.00 MB   ← Will be deleted after 5 days
```

## What Gets Preserved?

**Tagged Images:**
- All production images with tags like `20251119-7`, `20251120-6`, `61`, etc.
- No limit on number of tagged images
- Preserved forever until manually deleted

**Example from your ECR:**
```
✅ 20251119-7      23.26 MB  ← Preserved
✅ 20251119-6      23.26 MB  ← Preserved
✅ 61              23.26 MB  ← Preserved
```

## Applying the Policy

### Using Terraform (Recommended)

1. **Navigate to Terraform directory:**
   ```bash
   cd Jenkins-Server-TF/
   ```

2. **Review the changes:**
   ```bash
   terraform plan
   ```

3. **Apply the lifecycle policies:**
   ```bash
   terraform apply
   ```

4. **Verify application:**
   ```bash
   terraform output ecr_lifecycle_policies
   ```

### Using AWS CLI (Alternative)

If you prefer to apply manually without Terraform:

**Frontend:**
```bash
aws ecr put-lifecycle-policy \
  --repository-name frontend \
  --lifecycle-policy-text file://ecr-lifecycle-policy.json
```

**Backend:**
```bash
aws ecr put-lifecycle-policy \
  --repository-name backend \
  --lifecycle-policy-text file://ecr-lifecycle-policy.json
```

**Policy JSON (`ecr-lifecycle-policy.json`):**
```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep all tagged images (no expiration)",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["20"],
        "countType": "imageCountMoreThan",
        "countNumber": 9999
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Delete untagged images older than 5 days (cache cleanup)",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 5
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

## Verification

### Check Applied Policies
```bash
# Frontend
aws ecr get-lifecycle-policy --repository-name frontend

# Backend
aws ecr get-lifecycle-policy --repository-name backend
```

### Monitor Cleanup
```bash
# List images in repository
aws ecr list-images --repository-name frontend

# Check untagged image count
aws ecr list-images --repository-name frontend \
  --filter tagStatus=UNTAGGED \
  --query 'imageIds[*]' --output text | wc -l
```

## Benefits

✅ **Cost Savings:** Reduces storage costs by removing unused cache layers
✅ **Automated:** No manual cleanup required
✅ **Safe:** All production images (tagged) are preserved
✅ **Version Controlled:** Policy managed in Terraform for consistency
✅ **Compliance:** Meets image retention best practices

## Expected Impact

From your current ECR (138 images in frontend):
- **Tagged images:** ~13-20 images → All preserved ✅
- **Untagged images:** ~118-125 images → Cleanup after 5 days 🗑️
- **Storage reduction:** ~70-90% reduction in stored images
- **Cost savings:** Approximately $1-2/month per repository

## Policy Execution

- **Runs:** Daily (AWS manages schedule)
- **First cleanup:** Within 24 hours of policy application
- **Ongoing:** Automatic daily evaluation

## Rollback

If you need to disable the policy:

```bash
# Using Terraform
terraform destroy -target=aws_ecr_lifecycle_policy.frontend
terraform destroy -target=aws_ecr_lifecycle_policy.backend

# Using AWS CLI
aws ecr delete-lifecycle-policy --repository-name frontend
aws ecr delete-lifecycle-policy --repository-name backend
```

## Notes

- Policy does NOT affect currently running containers
- Untagged images are Docker cache layers from multi-stage builds
- Tagged images include all your date-based versions (YYYYMMDD-BUILD)
- Policy execution logs available in CloudTrail

## References

- [AWS ECR Lifecycle Policies Documentation](https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html)
- [ECR Lifecycle Policy Examples](https://docs.aws.amazon.com/AmazonECR/latest/userguide/lifecycle_policy_examples.html)
