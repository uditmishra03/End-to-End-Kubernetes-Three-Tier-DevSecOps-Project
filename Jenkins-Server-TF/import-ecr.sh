#!/bin/bash
# Script to import existing ECR repositories into Terraform state

set -e

echo "🔄 Importing existing ECR repositories into Terraform..."
echo ""

# Check if repositories exist
echo "📋 Checking if ECR repositories exist..."
aws ecr describe-repositories --repository-names frontend backend --region us-east-1 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Both frontend and backend repositories found"
else
    echo "❌ One or both repositories not found. Please create them first."
    exit 1
fi

echo ""
echo "📥 Importing frontend repository..."
terraform import -var-file="variables.tfvars" aws_ecr_repository.frontend frontend

echo ""
echo "📥 Importing backend repository..."
terraform import -var-file="variables.tfvars" aws_ecr_repository.backend backend

echo ""
echo "✅ Import complete! Now you can manage ECR repositories with Terraform."
echo ""
echo "🚀 Next steps:"
echo "   1. Run: terraform plan -var-file='variables.tfvars'"
echo "   2. Run: terraform apply -var-file='variables.tfvars'"
echo ""
