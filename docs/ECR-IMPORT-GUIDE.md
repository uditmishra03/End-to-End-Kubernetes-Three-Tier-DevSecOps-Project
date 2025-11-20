# ECR Repository Import Guide

## Overview
This guide walks you through importing existing ECR repositories into Terraform state management.

## Prerequisites
- Existing `frontend` and `backend` ECR repositories in AWS
- AWS CLI configured with appropriate credentials
- Terraform installed
- Access to the `Jenkins-Server-TF` directory

## Step-by-Step Import Process

### Method 1: Using the Import Script (Recommended)

1. **Navigate to Terraform directory:**
   ```bash
   cd ~/temp-repo/Jenkins-Server-TF
   ```

2. **Make script executable:**
   ```bash
   chmod +x import-ecr.sh
   ```

3. **Run the import script:**
   ```bash
   ./import-ecr.sh
   ```

4. **Verify import:**
   ```bash
   terraform plan -var-file="variables.tfvars"
   ```

5. **Apply lifecycle policies:**
   ```bash
   terraform apply -var-file="variables.tfvars"
   ```

### Method 2: Manual Import

1. **Navigate to Terraform directory:**
   ```bash
   cd ~/temp-repo/Jenkins-Server-TF
   ```

2. **Import frontend repository:**
   ```bash
   terraform import aws_ecr_repository.frontend frontend
   ```

3. **Import backend repository:**
   ```bash
   terraform import aws_ecr_repository.backend backend
   ```

4. **Verify import:**
   ```bash
   terraform state list | grep ecr
   ```
   
   Expected output:
   ```
   aws_ecr_repository.frontend
   aws_ecr_repository.backend
   aws_ecr_lifecycle_policy.frontend
   aws_ecr_lifecycle_policy.backend
   ```

5. **Check plan:**
   ```bash
   terraform plan -var-file="variables.tfvars"
   ```

6. **Apply changes:**
   ```bash
   terraform apply -var-file="variables.tfvars"
   ```

## Verification Steps

### 1. Check Terraform State
```bash
# List all ECR resources in state
terraform state list | grep ecr

# Show frontend repository details
terraform state show aws_ecr_repository.frontend

# Show backend repository details
terraform state show aws_ecr_repository.backend
```

### 2. Verify Lifecycle Policies
```bash
# Check frontend policy
aws ecr get-lifecycle-policy --repository-name frontend

# Check backend policy
aws ecr get-lifecycle-policy --repository-name backend
```

### 3. Review Repository Configuration
```bash
# Describe frontend repository
aws ecr describe-repositories --repository-names frontend

# Describe backend repository
aws ecr describe-repositories --repository-names backend
```

## Expected Output After Apply

```bash
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

ecr_lifecycle_policies = {
  "backend" = {
    "policy_applied" = "Untagged images deleted after 5 days, all tagged images preserved"
    "repository" = "backend"
  }
  "frontend" = {
    "policy_applied" = "Untagged images deleted after 5 days, all tagged images preserved"
    "repository" = "frontend"
  }
}
ecr_repository_arns = {
  "backend" = "arn:aws:ecr:us-east-1:296062548155:repository/backend"
  "frontend" = "arn:aws:ecr:us-east-1:296062548155:repository/frontend"
}
ecr_repository_urls = {
  "backend" = "296062548155.dkr.ecr.us-east-1.amazonaws.com/backend"
  "frontend" = "296062548155.dkr.ecr.us-east-1.amazonaws.com/frontend"
}
```

## What Gets Managed by Terraform

After import, Terraform will manage:

✅ **ECR Repositories:**
- Repository name
- Image tag mutability (MUTABLE)
- Image scanning (enabled on push)
- Encryption (AES256)
- Tags

✅ **Lifecycle Policies:**
- Rule to preserve all tagged images
- Rule to delete untagged images after 5 days

## Important Notes

⚠️ **Do NOT delete repositories after import**
- Terraform now manages the lifecycle, not creation
- Deleting via console will cause state drift
- Always use `terraform destroy` if needed

⚠️ **Existing Images Are Safe**
- Import does NOT affect existing images
- All images remain in the repository
- Lifecycle policies only apply going forward

⚠️ **State File Backup**
- Terraform state now contains ECR configuration
- Ensure `terraform.tfstate` is backed up
- Consider using remote state (S3 + DynamoDB)

## Troubleshooting

### Error: Resource Already Exists
```
Error: resource already exists
```

**Solution:** Repository is already in state. Check:
```bash
terraform state list | grep ecr
```

### Error: Repository Not Found
```
Error: repository does not exist
```

**Solution:** Verify repository exists:
```bash
aws ecr describe-repositories --repository-names frontend backend
```

### Plan Shows Changes After Import
This is normal if:
- Tags differ from Terraform configuration
- Image scanning settings differ
- Encryption type differs

Run `terraform apply` to align the configuration.

## Rollback (If Needed)

If something goes wrong during import:

```bash
# Remove from Terraform state (keeps AWS resources)
terraform state rm aws_ecr_repository.frontend
terraform state rm aws_ecr_repository.backend

# Then re-import
./import-ecr.sh
```

## Next Steps After Successful Import

1. ✅ Push changes to Git repository
2. ✅ Document ECR management in team wiki
3. ✅ Set up Terraform remote state (optional)
4. ✅ Enable automated Terraform runs (CI/CD)
5. ✅ Monitor lifecycle policy execution (CloudTrail)

## Files Created

- `ecr_repositories.tf` - ECR repository definitions
- `ecr_lifecycle_policies.tf` - Lifecycle policy rules
- `import-ecr.sh` - Automated import script
- `ECR-IMPORT-GUIDE.md` - This guide

## References

- [Terraform Import Documentation](https://www.terraform.io/docs/cli/import/index.html)
- [AWS ECR Terraform Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository)
- [ECR Lifecycle Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html)
