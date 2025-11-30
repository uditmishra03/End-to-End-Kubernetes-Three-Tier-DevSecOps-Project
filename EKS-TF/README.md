# 🚀 EKS Cluster Terraform Configuration

Complete Infrastructure as Code for deploying the Three-Tier DevSecOps EKS cluster with all required add-ons and controllers.

---

## 📋 What Gets Created

### Core Infrastructure
- **VPC** with public and private subnets across 3 availability zones
- **NAT Gateways** for high availability (one per AZ)
- **Internet Gateway** for public subnet access
- **Route tables** and subnet associations

### EKS Cluster
- **EKS Control Plane** (Kubernetes 1.32)
- **Managed Node Group** with 2-3 t2.medium instances
- **OIDC Provider** for IAM Roles for Service Accounts (IRSA)
- **Security groups** for cluster and node communication

### Add-ons & Controllers
- **VPC CNI** with IRSA for pod networking (with prefix delegation enabled)
- **CoreDNS** for service discovery
- **kube-proxy** for network proxy
- **EBS CSI Driver** with IRSA for persistent volumes
- **AWS Load Balancer Controller** with IRSA for ALB/NLB provisioning (auto-installed via Helm)

### IAM Resources
- IAM roles for EKS nodes
- IAM roles for service accounts (IRSA):
  - VPC CNI controller
  - EBS CSI driver
  - AWS Load Balancer Controller
- Required IAM policies attached to roles

---

## 🚀 Quick Start

### Prerequisites

Before you begin, ensure you have:

1. **AWS CLI** configured with appropriate credentials
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Access Key, and region (us-east-1)
   ```

2. **Terraform** >= 1.0 installed
   ```bash
   terraform version
   # Should show version 1.0 or higher
   ```

3. **kubectl** installed
   ```bash
   kubectl version --client
   ```

4. **S3 Backend** already exists from Jenkins-Server-TF setup:
   - S3 bucket: `eks-devsecops-bucket`
   - DynamoDB table: `Lock-Files`

### Step 1: Review Configuration

Navigate to this directory and review the default configuration:

```bash
cd EKS-TF

# Review the default configuration
cat variables.tfvars
```

**Key configurations you can modify in `variables.tfvars`:**

```hcl
# Cluster version (current: 1.32)
cluster_version = "1.32"

# Node group sizing
node_desired_size = 2    # Start with 2 nodes
node_min_size     = 2    # Minimum 2 nodes
node_max_size     = 3    # Scale up to 3 nodes

# Instance type (t2.medium is default)
node_instance_types = ["t2.medium"]

# Disk size per node
node_disk_size = 20  # GB
```

### Step 2: Initialize Terraform

```bash
# Initialize Terraform and download required providers
terraform init

# Expected output:
# - Downloads AWS, Kubernetes, and Helm providers
# - Configures S3 backend
# - Initializes modules from Terraform Registry
```

**What this does:**
- Downloads provider plugins (AWS ~5.0, Kubernetes ~2.23, Helm ~2.11)
- Configures remote state in S3 bucket
- Downloads AWS VPC, EKS, and IAM modules

### Step 3: Review the Plan

```bash
# See what will be created
terraform plan -var-file=variables.tfvars

# Expected output: ~60-80 resources to be created
```

**Resources that will be created:**
- VPC with 3 public + 3 private subnets
- 3 NAT Gateways (one per AZ)
- Internet Gateway
- EKS Cluster (control plane)
- Managed Node Group with 2-3 nodes
- OIDC Provider for IRSA
- IAM roles for node group, VPC CNI, EBS CSI Driver, and ALB Controller
- Cluster add-ons: CoreDNS, kube-proxy, VPC CNI, EBS CSI Driver
- AWS Load Balancer Controller (via Helm)

### Step 4: Apply Configuration

```bash
# Deploy the infrastructure
terraform apply -var-file=variables.tfvars

# Review the plan one more time, then type: yes
```

**Timeline:**
- ⏱️ **Total time:** 20-25 minutes
- VPC creation: ~2 minutes
- EKS control plane: ~10-12 minutes
- Node group: ~5-7 minutes
- Add-ons & controllers: ~3-5 minutes

### Step 5: Configure kubectl

Once Terraform completes successfully:

```bash
# Get the command from Terraform output
terraform output configure_kubectl

# Or run directly:
aws eks update-kubeconfig --region us-east-1 --name Three-Tier-K8s-EKS-Cluster

# Verify cluster access
kubectl get nodes

# Expected output:
# NAME                         STATUS   ROLES    AGE     VERSION
# ip-10-0-11-xxx.ec2.internal  Ready    <none>   5m      v1.32.x
# ip-10-0-12-xxx.ec2.internal  Ready    <none>   5m      v1.32.x
```

### Step 6: Verify Installation

Run these verification checks to ensure everything is working:

```bash
# 1. Check cluster info
kubectl cluster-info

# 2. Verify all nodes are Ready
kubectl get nodes

# 3. Check system pods
kubectl get pods -n kube-system

# 4. Verify AWS Load Balancer Controller
kubectl get deployment -n kube-system aws-load-balancer-controller
# Expected: 2/2 READY

# 5. Check EBS CSI Driver
kubectl get pods -n kube-system -l app=ebs-csi-controller
# Expected: 2 pods running

# 6. View all Terraform outputs
terraform output
```

### Step 7: Success!

Your cluster is ready when you see:
- ✅ `terraform apply` completed successfully
- ✅ All nodes show `STATUS: Ready`
- ✅ All `kube-system` pods are `Running` or `Completed`
- ✅ AWS Load Balancer Controller deployment shows `2/2 READY`
- ✅ EBS CSI controller pods are `Running`

**Next Steps:** Proceed with application deployment (MongoDB, ArgoCD, etc.) as documented in the main [GETTING-STARTED.md](../docs/GETTING-STARTED.md) guide.

---

## 🔧 Configuration & Customization

### Modifying Cluster Settings

Edit `variables.tfvars` to customize your deployment:

```hcl
# Change cluster version
cluster_version = "1.32"

# Adjust node group size
node_desired_size = 3    # Increase to 3 nodes
node_min_size     = 2
node_max_size     = 5

# Change instance type
node_instance_types = ["t3.medium"]  # Use t3 instead of t2

# Modify VPC CIDR
vpc_cidr = "10.0.0.0/16"

# Change environment
environment = "staging"  # or "development", "production"
```

After making changes:
```bash
terraform plan -var-file=variables.tfvars   # Review changes
terraform apply -var-file=variables.tfvars  # Apply changes
```

### Scaling Node Group

To scale the node group up or down:

```bash
# Edit variables.tfvars
node_desired_size = 4

# Apply the change
terraform apply -var-file=variables.tfvars

# Kubernetes will automatically schedule pods on new nodes
```

---

## 📊 Outputs

After successful deployment, Terraform provides important outputs:

```bash
# View all outputs
terraform output

# View specific outputs
terraform output cluster_endpoint            # EKS API server endpoint
terraform output oidc_provider_arn          # OIDC provider ARN for IRSA
terraform output vpc_id                     # VPC ID
terraform output private_subnets            # Private subnet IDs
terraform output public_subnets             # Public subnet IDs
terraform output load_balancer_controller_role_arn  # ALB controller IAM role
```

**Key Outputs:**
- `cluster_endpoint` - Use to connect to Kubernetes API
- `oidc_provider_arn` - Required for creating additional IRSA roles
- `configure_kubectl` - Command to configure kubectl access
- `vpc_id` - VPC ID for reference in other resources
- `load_balancer_controller_role_arn` - IAM role for ALB controller

---

## 🧹 Cleanup

**CRITICAL:** Always delete Kubernetes resources BEFORE destroying Terraform infrastructure!

### Step 1: Delete Kubernetes Resources

```bash
# Delete all application namespaces (this removes ALBs, NLBs, etc.)
kubectl delete namespace three-tier --wait=true
kubectl delete namespace database --wait=true
kubectl delete namespace argocd --wait=true
kubectl delete namespace monitoring --wait=true

# Delete any remaining ingress resources
kubectl delete ingress --all --all-namespaces

# Wait 2-3 minutes for AWS load balancers to be fully deleted
# You can check in AWS Console: EC2 → Load Balancers
```

**Why this is important:**
- Kubernetes-created ALBs/NLBs are not tracked by Terraform
- Deleting them first prevents VPC deletion failures
- Ensures clean removal of all AWS resources

### Step 2: Destroy Terraform Infrastructure

```bash
cd EKS-TF

# Destroy all infrastructure
terraform destroy -var-file=variables.tfvars

# Review the plan, then type: yes

# Expected time: 15-20 minutes
```

**What gets deleted:**
- EKS cluster and node group
- All IAM roles and policies
- Load Balancer Controller
- VPC, subnets, NAT gateways, Internet Gateway
- Security groups
- OIDC provider

### Step 3: Verify Cleanup

```bash
# Verify cluster is deleted
aws eks describe-cluster --name Three-Tier-K8s-EKS-Cluster --region us-east-1
# Expected: ResourceNotFoundException

# Check for orphaned VPCs
aws ec2 describe-vpcs --region us-east-1 --filters "Name=tag:Name,Values=three-tier-eks-vpc"
# Expected: Empty result

# Check for orphaned load balancers
aws elbv2 describe-load-balancers --region us-east-1 | grep Three-Tier
# Expected: Empty result
```

---

## 🔍 Troubleshooting

### Issue: Terraform Init Fails

**Error:** "Error configuring S3 Backend"

**Solution:**
```bash
# Verify S3 bucket exists
aws s3 ls s3://eks-devsecops-bucket

# Verify DynamoDB table exists
aws dynamodb describe-table --table-name Lock-Files --region us-east-1

# If missing, create them (they should exist from Jenkins-Server-TF setup)
```

### Issue: Node Group Not Ready

**Error:** Nodes stuck in "NotReady" state

**Solution:**
```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name Three-Tier-K8s-EKS-Cluster \
  --nodegroup-name three-tier-node-group \
  --region us-east-1

# Describe nodes for issues
kubectl describe node <node-name>

# Check VPC CNI pods
kubectl get pods -n kube-system -l k8s-app=aws-node

# View node logs (if needed)
aws ec2 get-console-output --instance-id <instance-id> --region us-east-1
```

### Issue: ALB Controller Not Working

**Error:** Ingress not creating load balancers

**Solution:**
```bash
# Check controller logs
kubectl logs -n kube-system \
  -l app.kubernetes.io/name=aws-load-balancer-controller \
  --tail=100

# Verify IRSA annotation on service account
kubectl describe sa aws-load-balancer-controller -n kube-system
# Should show: eks.amazonaws.com/role-arn annotation

# Check IAM role permissions
aws iam get-role --role-name <alb-controller-role-name>

# Restart controller if needed
kubectl rollout restart deployment/aws-load-balancer-controller -n kube-system
```

### Issue: Destroy Fails with VPC Dependencies

**Error:** "Error deleting VPC: has dependencies"

**Solution:**
```bash
# This usually means Kubernetes resources weren't deleted first!

# Force delete all ingresses
kubectl delete ingress --all --all-namespaces --force --grace-period=0

# Delete all services of type LoadBalancer
kubectl delete service --all --all-namespaces --field-selector spec.type=LoadBalancer

# Check for orphaned ENIs
VPC_ID=$(terraform output -raw vpc_id)
aws ec2 describe-network-interfaces --region us-east-1 \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'NetworkInterfaces[*].[NetworkInterfaceId,Description,Status]' \
  --output table

# Delete orphaned ENIs if found
aws ec2 delete-network-interface --network-interface-id <ENI-ID> --region us-east-1

# Retry destroy
terraform destroy -var-file=variables.tfvars
```

### Issue: State Lock Error

**Error:** "Error acquiring the state lock"

**Solution:**
```bash
# Check if another terraform operation is running
# If not, force unlock (use the Lock ID from error message)
terraform force-unlock <LOCK-ID>

# Retry your command
terraform apply -var-file=variables.tfvars
```

---

## 🎯 Why Terraform Instead of eksctl?

### Real-World Lessons Learned (November 30, 2025)

**We experienced a painful 2+ hour eksctl cleanup that inspired this Terraform solution.**

#### What Actually Happened with eksctl Cleanup:

1. **Initial Deletion Attempt Failed**
   - `eksctl delete cluster` timed out after 25+ minutes
   - Cluster control plane stuck with "Cluster has nodegroups attached" error
   - CloudFormation stack: `DELETE_FAILED`

2. **IAM Role Dependency Chain Broke**
   - Manually deleted IAM role: `eksctl-Three-Tier-K8s-EKS-Cluster--NodeInstanceRole-1PLh0fSgNKtC`
   - This broke eksctl's CloudFormation dependency chain
   - Nodegroup couldn't delete because IAM role was missing
   - Had to manually delete instance profile: `eks-7ccd6a65-f771-7cf3-37d7-6913d7c0ac67`

3. **Auto Scaling Group Got Stuck**
   - ASG: `eks-ng-20251130-124517-7ccd6a65-f771-7cf3-37d7-6913d7c0ac67`
   - Couldn't delete because IAM role was gone
   - Had to force delete: `aws autoscaling delete-auto-scaling-group --force-delete`
   - Manual intervention on running EC2 instances

4. **VPC Deletion Failed Multiple Times**
   - Error: "VPC has dependencies and cannot be deleted"
   - **3 orphaned security groups** from Kubernetes load balancers:
     - `sg-0b402db07339f418f` - k8s-elb-a67ead43b50804a41bd (ArgoCD Classic LB)
     - `sg-014e522e2b46a1ed6` - k8s-traffic-mycluster-4cbfcec96c (Shared backend)
     - `sg-0f395f2d4158835d3` - k8s-threetie-mainlb-4183b8bf64 (Main ALB)
   - Had to manually delete each security group
   - VPC ID: `vpc-0c536758a10e29c06`

5. **Failed CloudFormation Stacks**
   - Stack: `eksctl-Three-Tier-K8s-EKS-Cluster-nodegroup-ng-960b346f` - `DELETE_FAILED`
   - Had to manually delete: `aws cloudformation delete-stack --force`
   - Multiple retry attempts required

#### Manual Steps Required to Complete Cleanup:

```bash
# 1. Get instance profile from CloudFormation
aws cloudformation describe-stack-resources --stack-name <stack> --query ...

# 2. Remove role from instance profile
aws iam remove-role-from-instance-profile --instance-profile-name <profile> --role-name <role>

# 3. Delete instance profile
aws iam delete-instance-profile --instance-profile-name <profile>

# 4. Delete IAM role
aws iam delete-role --role-name <role>

# 5. Delete failed CloudFormation stack
aws cloudformation delete-stack --stack-name <stack>

# 6. Force delete Auto Scaling Group
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name <asg> --force-delete

# 7. Delete orphaned security groups (one by one)
aws ec2 delete-security-group --group-id sg-0b402db07339f418f
aws ec2 delete-security-group --group-id sg-014e522e2b46a1ed6
aws ec2 delete-security-group --group-id sg-0f395f2d4158835d3

# 8. Retry cluster stack deletion
aws cloudformation delete-stack --stack-name eksctl-Three-Tier-K8s-EKS-Cluster-cluster

# 9. Verify everything is deleted
aws eks describe-cluster --name Three-Tier-K8s-EKS-Cluster  # Should fail
aws ec2 describe-vpcs --filters "Name=vpc-id,Values=vpc-0c536758a10e29c06"  # Should be empty
```

**Total time: 2+ hours, 9 manual intervention steps, multiple failures and retries**

#### Additional Lesson: ECR Repository Cleanup (November 30, 2025)

During Jenkins Server Terraform cleanup, we encountered another issue:

```
Error: ECR Repository (backend) not empty, consider using force_delete
Error: ECR Repository (frontend) not empty, consider using force_delete
```

**Problem**: ECR repositories couldn't be deleted because they contained Docker images from our CI/CD pipeline builds.

**Solution**: Added `force_delete = true` to ECR repository resources:

```terraform
resource "aws_ecr_repository" "backend" {
  name                 = "backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true  # ← This allows deletion even with images

  image_scanning_configuration {
    scan_on_push = true
  }
  # ... rest of config
}
```

**Why This Matters**: 
- ECR repositories accumulate images over time from CI/CD builds
- Without `force_delete = true`, you must manually delete all images before destroying the repository
- With this flag, Terraform handles cleanup automatically
- **Recommendation**: Always set `force_delete = true` for ECR repositories in non-production environments

---

### With Terraform: The Clean Solution

```bash
# Step 1: Delete Kubernetes resources (prevents orphaned AWS resources)
kubectl delete namespace three-tier database argocd monitoring --wait=true

# Step 2: Destroy infrastructure
cd EKS-TF
terraform destroy -var-file=variables.tfvars

# Done! All resources deleted cleanly in 15-20 minutes
# No manual steps, no orphaned resources, no broken dependency chains
```

---

### Benefits of This Approach

1. **Declarative State Management**
   - Complete infrastructure as code
   - State tracked in S3 backend
   - Easy rollback with `terraform plan`

2. **Simple Cleanup**
   - Single `terraform destroy` command
   - No manual resource hunting
   - Proper dependency ordering

3. **Version Control**
   - All changes tracked in Git
   - Review changes before applying
   - Team collaboration friendly

4. **Reproducibility**
   - Exact same cluster every time
   - No manual steps required
   - Environment parity (dev/staging/prod)

5. **Integrated Add-ons**
   - ALB Controller installed automatically
   - EBS CSI Driver configured with IRSA
   - All IAM roles properly created

### Comparison with eksctl

| Feature | eksctl | Terraform (This Solution) |
|---------|--------|---------------------------|
| **Cleanup** | Manual multi-step process, often fails | `terraform destroy` - single command |
| **State Management** | CloudFormation only | S3 backend with full state tracking |
| **IAM Role Tracking** | Partial, easily breaks | Complete, all roles tracked |
| **VPC Management** | Separate or limited | Fully integrated |
| **Add-on Installation** | Manual Helm commands | Automated in code |
| **Modification** | Recreate or manual | Plan → Apply with preview |
| **Team Collaboration** | Difficult | Git-based workflow |
| **Disaster Recovery** | Manual recreation | `terraform apply` restores everything |

---

## 📚 Additional Resources

- **Terraform AWS EKS Module:** https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
- **AWS Load Balancer Controller Docs:** https://kubernetes-sigs.github.io/aws-load-balancer-controller/
- **EBS CSI Driver Documentation:** https://github.com/kubernetes-sigs/aws-ebs-csi-driver
- **EKS Best Practices Guide:** https://aws.github.io/aws-eks-best-practices/
- **Terraform AWS Provider:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs

---

## 💡 Tips & Best Practices

### Cost Management

1. **Stop cluster when not in use:**
   ```bash
   # Scale node group to 0
   # Edit variables.tfvars: node_desired_size = 0
   terraform apply -var-file=variables.tfvars
   
   # Scale back up when needed
   # Edit variables.tfvars: node_desired_size = 2
   terraform apply -var-file=variables.tfvars
   ```

2. **NAT Gateway costs:**
   - You have 3 NAT Gateways (~$0.045/hour each = ~$3.24/day total)
   - Consider single NAT for dev environments by modifying `vpc.tf`

3. **Monitor costs:**
   ```bash
   aws ce get-cost-and-usage \
     --time-period Start=2025-11-01,End=2025-11-30 \
     --granularity MONTHLY \
     --metrics "BlendedCost" \
     --filter file://filter.json
   ```

### Upgrading Kubernetes

1. **Update cluster version:**
   ```bash
   # Edit variables.tfvars
   cluster_version = "1.33"  # New version
   
   # Plan the upgrade
   terraform plan -var-file=variables.tfvars
   
   # Apply (control plane upgrades first, then nodes)
   terraform apply -var-file=variables.tfvars
   ```

2. **Upgrade add-ons after cluster upgrade:**
   - Terraform will automatically update add-ons
   - Review addon versions in `eks.tf` if needed

### State Management

1. **Never delete state files:**
   - S3 bucket: `eks-devsecops-bucket`
   - DynamoDB table: `Lock-Files`
   - State contains sensitive data - keep secure

2. **Inspect state:**
   ```bash
   terraform state list                    # List all resources
   terraform state show module.eks.cluster # Show specific resource
   ```

3. **Backup state:**
   ```bash
   # State is already backed up in S3 with versioning
   aws s3api list-object-versions \
     --bucket eks-devsecops-bucket \
     --prefix eks/terraform.tfstate
   ```

### Security

1. **Enable encryption:**
   - All EBS volumes use encrypted disks (default)
   - Secrets stored in Kubernetes are encrypted at rest

2. **IRSA for all service accounts:**
   - No static AWS credentials in pods
   - Temporary credentials via OIDC
   - Follows AWS security best practices

3. **Network isolation:**
   - Nodes in private subnets
   - Control plane endpoint can be made private (modify `eks.tf`)

---

## 🤝 Contributing

When making changes to this infrastructure:

1. **Always test in a non-production environment first**
2. **Run `terraform fmt`** to format code
3. **Run `terraform validate`** to check syntax
4. **Create a plan file** for review:
   ```bash
   terraform plan -var-file=variables.tfvars -out=tfplan
   ```
5. **Document changes** in this README
6. **Update variables** if new options added

---

## 📝 File Structure

```
EKS-TF/
├── provider.tf                      # AWS, Kubernetes, Helm providers + S3 backend
├── variables.tf                     # Variable definitions
├── variables.tfvars                 # Default values (customize this)
├── vpc.tf                           # VPC, subnets, NAT gateways, IGW
├── eks.tf                           # EKS cluster, node groups, add-ons, IRSA
├── aws-load-balancer-controller.tf  # ALB controller IAM + Helm installation
├── outputs.tf                       # Output values (endpoints, ARNs, IDs)
├── README.md                        # This file (complete documentation)
└── .gitignore                       # Terraform-specific ignore rules
```

---

**🎯 You now have a fully functional, production-ready EKS cluster managed entirely with Terraform!**

Need help? Check the troubleshooting section above or open an issue in the repository.

```hcl
# Change cluster version
cluster_version = "1.32"

# Adjust node group size
node_desired_size = 2
node_min_size     = 2
node_max_size     = 3

# Change instance type
node_instance_types = ["t2.medium"]

# Modify VPC CIDR
vpc_cidr = "10.0.0.0/16"
```

### Scaling Node Group

```bash
# Update variables.tfvars with new sizes
node_desired_size = 4
node_min_size     = 2
node_max_size     = 6

# Apply changes
terraform apply -var-file=variables.tfvars
```

## 📊 Outputs

After successful deployment, Terraform provides:

- `cluster_endpoint` - EKS API server endpoint
- `cluster_name` - Name of the EKS cluster
- `oidc_provider_arn` - OIDC provider ARN for IRSA
- `vpc_id` - VPC ID
- `private_subnets` - Private subnet IDs
- `public_subnets` - Public subnet IDs
- `load_balancer_controller_role_arn` - IAM role ARN for ALB controller
- `configure_kubectl` - Command to configure kubectl

View all outputs:
```bash
terraform output
```

## 🧹 Cleanup

**IMPORTANT:** This is the proper way to destroy the EKS infrastructure!

### Step 1: Delete Kubernetes Resources First

Before running `terraform destroy`, delete all application resources to avoid orphaned AWS resources:

```bash
# Delete all deployments and services in application namespaces
kubectl delete namespace three-tier --wait=true
kubectl delete namespace database --wait=true
kubectl delete namespace argocd --wait=true
kubectl delete namespace monitoring --wait=true

# Delete any ingress resources
kubectl delete ingress --all --all-namespaces

# Wait for ALBs to be deleted (check AWS Console)
# This usually takes 2-3 minutes
```

### Step 2: Run Terraform Destroy

```bash
# Destroy all Terraform-managed resources
terraform destroy -var-file=variables.tfvars -auto-approve
```

**Expected duration:** 15-20 minutes

### Step 3: Verify Cleanup

```bash
# Verify cluster is deleted
aws eks describe-cluster --name Three-Tier-K8s-EKS-Cluster --region us-east-1
# Should return: ResourceNotFoundException

# Check for orphaned resources
aws ec2 describe-vpcs --region us-east-1 --filters "Name=tag:Name,Values=three-tier-eks-vpc"
# Should return empty

# Check for orphaned load balancers
aws elbv2 describe-load-balancers --region us-east-1 | grep Three-Tier
# Should return empty
```

## 🎯 Why Terraform Instead of eksctl?

### Benefits of This Approach

1. **Declarative State Management**
   - Complete infrastructure as code
   - State tracked in S3 backend
   - Easy rollback with `terraform plan`

2. **Simple Cleanup**
   - Single `terraform destroy` command
   - No manual resource hunting
   - Proper dependency ordering

3. **Version Control**
   - All changes tracked in Git
   - Review changes before applying
   - Team collaboration friendly

4. **Reproducibility**
   - Exact same cluster every time
   - No manual steps required
   - Environment parity (dev/staging/prod)

5. **Integrated Add-ons**
   - ALB Controller installed automatically
   - EBS CSI Driver configured with IRSA
   - All IAM roles properly created

### Comparison with eksctl

| Feature | Terraform | eksctl |
|---------|-----------|--------|
| Cleanup | `terraform destroy` | Manual CloudFormation + manual IAM cleanup |
| State Management | Yes (S3 backend) | No (CloudFormation only) |
| IAM Role Tracking | Complete | Partial |
| VPC Management | Fully integrated | Separate or limited |
| Add-on Installation | Automated | Manual Helm commands |
| Modification | Plan → Apply | Recreate or manual |

## 🔍 Troubleshooting

### Issue: Terraform Init Fails

**Solution:**
```bash
# Ensure S3 bucket and DynamoDB table exist
aws s3 ls s3://eks-devsecops-bucket
aws dynamodb describe-table --table-name Lock-Files --region us-east-1
```

### Issue: Node Group Not Ready

**Solution:**
```bash
# Check node group status
kubectl get nodes

# Check for issues
kubectl describe node <node-name>

# Verify IAM role permissions
aws iam get-role --role-name <node-role-name>
```

### Issue: ALB Controller Not Working

**Solution:**
```bash
# Check controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Verify IRSA role
kubectl describe sa aws-load-balancer-controller -n kube-system

# Check IAM role permissions
aws iam get-role --role-name <alb-controller-role>
```

### Issue: Destroy Fails with VPC Dependencies

**Solution:**
```bash
# Delete all ingress resources first
kubectl delete ingress --all --all-namespaces

# Check for orphaned ENIs
aws ec2 describe-network-interfaces --region us-east-1 \
  --filters "Name=vpc-id,Values=<VPC-ID>" \
  --query 'NetworkInterfaces[*].[NetworkInterfaceId,Description]'

# Delete orphaned ENIs if found
aws ec2 delete-network-interface --network-interface-id <ENI-ID> --region us-east-1

# Retry destroy
terraform destroy -var-file=variables.tfvars
```

## 📚 Additional Resources

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [AWS Load Balancer Controller Docs](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EBS CSI Driver Docs](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)

## 🤝 Contributing

When making changes:
1. Update `variables.tf` and `variables.tfvars`
2. Run `terraform fmt` to format code
3. Run `terraform validate` to check syntax
4. Test in a non-production environment first
5. Document changes in this README

## 📝 Notes

- **State file** is stored in S3 bucket `eks-devsecops-bucket`
- **State locking** uses DynamoDB table `Lock-Files`
- **Default region** is `us-east-1`
- **Node instances** use AL2023 (Amazon Linux 2023) AMI
- **High availability** configured with multi-AZ subnets and NAT gateways
