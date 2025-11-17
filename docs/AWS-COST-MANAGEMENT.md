# AWS Cost Management Guide

**Purpose:** Safely stop and start AWS resources to minimize costs during non-working hours  
**Created:** November 17, 2025  
**Estimated Daily Savings:** ~$15-25/day when resources are stopped

---

## 💰 Current Cost Breakdown (Approximate)

| Resource | Cost (Running) | Cost (Stopped) | Savings |
|----------|---------------|----------------|---------|
| **Jenkins EC2 (t2.2xlarge)** | ~$0.33/hr ($7.92/day) | $0.13/hr (EBS only) | ~$5/day |
| **EKS Control Plane** | ~$0.10/hr ($2.40/day) | $0.10/hr (always charged) | $0 |
| **EKS Worker Nodes (2x t2.medium)** | ~$0.09/hr ($2.16/day) | $0 | ~$2.16/day |
| **Application Load Balancer** | ~$0.025/hr ($0.60/day) | $0 | ~$0.60/day |
| **EBS Volumes** | ~$0.10/GB/month | Same | $0 |
| **NAT Gateway** | ~$0.045/hr ($1.08/day) | Same | $0 |
| **ECR Storage** | ~$0.10/GB/month | Same | $0 |

**Total Daily Cost (Running):** ~$14-18/day  
**Total Daily Cost (Stopped):** ~$4-6/day  
**Daily Savings:** ~$10-12/day (~$300/month)

---

## ⚡ Quick Reference: Node Group Recreation

### **Critical Information to Save Before Deleting Node Group:**

| Item | Where to Find | Example Value |
|------|---------------|---------------|
| **Subnets** | EKS Console → Node Group → Details | subnet-0aa439b4ddafcca10, subnet-0b95df318219145ca |
| **Node IAM Role** | EKS Console → Node Group → Details | arn:aws:iam::296062548155:role/eksctl-Three-Tier-K8s-EKS-Cluster-NodeInstanceRole-xxxxx |
| **Instance Type** | Node Group → Details | t2.medium |
| **Disk Size** | Node Group → Details | 20 GB |
| **Scaling Config** | Node Group → Details | Desired: 2, Min: 1, Max: 3 |

**💡 Tip:** Take a screenshot of the node group details page before deleting!

---

### **Quick Recreate Steps (Console Method - No CLI Needed):**

1. **EKS Console** → **three-tier-cluster** → **Compute** → **Add node group**
2. **Name:** Any name (e.g., `ng-960b346f` or `three-tier-nodes`)
3. **IAM Role:** Select saved role
4. **Instance type:** t2.medium
5. **Scaling:** Desired=2, Min=1, Max=3
6. **Subnets:** Select saved subnets (usually 2-3 subnets)
7. **Create** → Wait 5-10 minutes

**Verify:** `kubectl get nodes` should show 2 nodes in Ready state

---

## 🛑 Phase 1: Shutdown Process (End of Day)

### Step 1: Backup Critical Data (5 minutes)

```bash
# 1. Backup MongoDB data
kubectl exec -n three-tier deployment/mongodb -- mongodump --out /backup --archive=/backup/mongodb-backup-$(date +%Y%m%d).archive

# 2. Copy backup locally (optional)
kubectl cp three-tier/<mongodb-pod>:/backup/mongodb-backup-$(date +%Y%m%d).archive ./backups/

# 3. Export ArgoCD applications
kubectl get applications -n argocd -o yaml > argocd-apps-backup.yaml

# 4. Commit any pending changes to Git
cd /path/to/project
git add .
git commit -m "End of day commit - $(date +%Y%m%d)"
git push origin master
```

### Step 2: Scale Down EKS Workloads (2 minutes)

```bash
# Scale down all deployments to 0 replicas
kubectl scale deployment frontend --replicas=0 -n three-tier
kubectl scale deployment api --replicas=0 -n three-tier
kubectl scale deployment mongodb --replicas=0 -n three-tier

# Verify
kubectl get pods -n three-tier

# Scale down ArgoCD (optional)
kubectl scale deployment argocd-server --replicas=0 -n argocd
kubectl scale deployment argocd-repo-server --replicas=0 -n argocd
kubectl scale deployment argocd-application-controller --replicas=0 -n argocd

# Scale down Prometheus/Grafana (optional)
kubectl scale deployment prometheus-grafana --replicas=0 -n monitoring
kubectl scale statefulset prometheus-kube-prometheus-prometheus --replicas=0 -n monitoring
```

### Step 3: Delete EKS Node Group (5 minutes)

**⚠️ This is the biggest cost saver! (~$2.16/day savings)**

#### **CRITICAL: Save Configuration First!**

Before deleting, go to **AWS Console** → **EKS** → **three-tier-cluster** → **Compute** tab → Click node group and **SAVE:**
- Subnets (2-3 subnet IDs)
- Node IAM Role ARN
- Instance type (t2.medium)
- Disk size (20 GB)
- Scaling config (2/1/3)

**Screenshot recommended!**

---

#### **Method 1: Delete via AWS Console (Easiest)**

1. Go to **AWS Console** → **EKS** → **three-tier-cluster** → **Compute** tab
2. Select node group (e.g., `ng-960b346f`)
3. Click **Delete**
4. Type node group name to confirm
5. Click **Delete**

**Wait 2-3 minutes for deletion to complete**

---

#### **Method 2: Delete via AWS CLI**

```powershell
aws eks delete-nodegroup `
  --cluster-name three-tier-cluster `
  --nodegroup-name ng-960b346f `
  --region us-east-1
```

---

#### **Method 3: Using eksctl (if installed)**

```bash
# List node groups first
eksctl get nodegroup --cluster three-tier-cluster --region us-east-1

# Delete the node group
eksctl delete nodegroup --cluster=three-tier-cluster --name=ng-960b346f --region us-east-1
```

---

#### **Verify Deletion:**

```powershell
# Check in AWS
aws eks list-nodegroups --cluster-name three-tier-cluster --region us-east-1

# Check in Kubernetes (nodes should disappear)
kubectl get nodes

# Expected output: No resources found
```

### Step 4: Stop Jenkins EC2 Instance (1 minute)

```bash
# Get instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=jenkins-server" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text --region us-east-1)

echo "Stopping Jenkins instance: $INSTANCE_ID"

# Stop the instance (saves ~$5/day)
aws ec2 stop-instances --instance-ids $INSTANCE_ID --region us-east-1

# Verify
aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[*].Instances[*].State" --region us-east-1
```

### Step 5: (Optional) Delete Load Balancer (1 minute)

**⚠️ Warning:** You'll need to recreate ingress tomorrow

```bash
# Delete ingress (ALB will be removed)
kubectl delete ingress mainlb -n three-tier

# Or manually delete ALB from AWS Console
# Navigate to EC2 → Load Balancers → Select ALB → Actions → Delete
```

---

## 🚀 Phase 2: Startup Process (Next Day)

### Step 1: Start Jenkins EC2 Instance (2 minutes)

```bash
# Get instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=jenkins-server" "Name=instance-state-name,Values=stopped" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text --region us-east-1)

echo "Starting Jenkins instance: $INSTANCE_ID"

# Start the instance
aws ec2 start-instances --instance-ids $INSTANCE_ID --region us-east-1

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region us-east-1

# Get new public IP (it will change!)
NEW_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --output text --region us-east-1)

echo "New Jenkins IP: $NEW_IP"
echo "Access Jenkins at: http://$NEW_IP:8080"
```

### Step 2: Recreate EKS Node Group (5-10 minutes)

⚠️ **IMPORTANT: Before deleting node group, save these details!**

#### **Before Deletion - Save Node Group Configuration:**

1. Go to **AWS Console** → **EKS** → **three-tier-cluster** → **Compute** tab
2. Click on node group name (e.g., `ng-960b346f`)
3. **SAVE THESE VALUES:**
   - **Subnets:** (e.g., subnet-xxxxx, subnet-yyyyy) - Usually 2-3 subnets
   - **Node IAM Role ARN:** (e.g., arn:aws:iam::296062548155:role/eksctl-Three-Tier-K8s-EKS-Cluster-NodeInstanceRole-xxxxx)
   - **Instance type:** t2.medium
   - **Disk size:** 20 GB (default)
   - **Desired/Min/Max size:** 2/1/3

**Screenshot or note these down!**

---

#### **Method 1: Recreate via AWS Console (Recommended - No CLI needed)**

1. **Go to:** AWS Console → EKS → Clusters → **three-tier-cluster** → **Compute** tab

2. **Click:** "Add node group"

3. **Configure node group:**
   - **Name:** `ng-960b346f` (or any name like `three-tier-nodes`)
   - **Node IAM Role:** Select the role you saved earlier
     - Format: `eksctl-Three-Tier-K8s-EKS-Cluster-NodeInstanceRole-xxxxx`
     - If not visible, select from dropdown
   - Click **Next**

4. **Set compute configuration:**
   - **AMI type:** Amazon Linux 2 (AL2_x86_64)
   - **Capacity type:** On-Demand
   - **Instance types:** t2.medium
   - **Disk size:** 20 GiB
   - Click **Next**

5. **Set scaling configuration:**
   - **Desired size:** 2
   - **Minimum size:** 1
   - **Maximum size:** 3
   - Click **Next**

6. **Specify networking:**
   - **Subnets:** Select the SAME subnets you saved earlier
     - Usually 2-3 subnets from different AZs (us-east-1a, us-east-1b, us-east-1c)
   - **Configure remote access:** No (leave unchecked unless you need SSH access)
   - Click **Next**

7. **Review and create:**
   - Review all settings
   - Click **Create**

**Wait 5-10 minutes for node group to be created and nodes to be Ready**

---

#### **Method 2: Using AWS CLI (PowerShell)**

**Prerequisites:** You need subnet IDs and IAM role ARN saved from before deletion

```powershell
# Replace these values with your saved configuration
$CLUSTER_NAME = "three-tier-cluster"
$NODEGROUP_NAME = "ng-960b346f-new"
$NODE_ROLE_ARN = "arn:aws:iam::296062548155:role/eksctl-Three-Tier-K8s-EKS-Cluster-NodeInstanceRole-xxxxx"
$SUBNET_IDS = "subnet-xxxxx,subnet-yyyyy,subnet-zzzzz"

# Create node group
aws eks create-nodegroup `
  --cluster-name $CLUSTER_NAME `
  --nodegroup-name $NODEGROUP_NAME `
  --scaling-config minSize=1,maxSize=3,desiredSize=2 `
  --disk-size 20 `
  --subnets $SUBNET_IDS `
  --instance-types t2.medium `
  --node-role $NODE_ROLE_ARN `
  --region us-east-1

# Wait for node group to be active
aws eks wait nodegroup-active `
  --cluster-name $CLUSTER_NAME `
  --nodegroup-name $NODEGROUP_NAME `
  --region us-east-1
```

---

#### **Method 3: Using eksctl (If you have it installed)**

```bash
# Recreate node group with same configuration
eksctl create nodegroup \
  --cluster=three-tier-cluster \
  --region=us-east-1 \
  --name=three-tier-nodes \
  --node-type=t2.medium \
  --nodes=2 \
  --nodes-min=1 \
  --nodes-max=3 \
  --managed
```

---

#### **Verify Node Group Creation:**

```powershell
# Check node group status in AWS
aws eks describe-nodegroup `
  --cluster-name three-tier-cluster `
  --nodegroup-name ng-960b346f `
  --region us-east-1

# Wait for nodes to be ready in Kubernetes
kubectl get nodes -w

# You should see output like:
# NAME                             STATUS   ROLES    AGE   VERSION
# ip-192-168-22-193.ec2.internal   Ready    <none>   2m    v1.32.9-eks-c39b1d0
# ip-192-168-36-77.ec2.internal    Ready    <none>   2m    v1.32.9-eks-c39b1d0
```

**Once you see 2 nodes with STATUS "Ready", proceed to next step!**

### Step 3: Configure kubectl Context (1 minute)

```bash
# Update kubeconfig
aws eks update-kubeconfig --name three-tier-cluster --region us-east-1

# Verify connection
kubectl get nodes
kubectl get ns
```

### Step 4: Recreate ECR Secret (2 minutes)

```bash
# Delete old secret
kubectl delete secret ecr-registry-secret -n three-tier 2>/dev/null

# Create new secret with fresh token
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --namespace=three-tier

# Verify
kubectl get secret ecr-registry-secret -n three-tier
```

### Step 5: Scale Up Applications (2 minutes)

```bash
# Scale up monitoring stack
kubectl scale statefulset prometheus-kube-prometheus-prometheus --replicas=1 -n monitoring
kubectl scale deployment prometheus-grafana --replicas=1 -n monitoring

# Scale up ArgoCD
kubectl scale deployment argocd-server --replicas=1 -n argocd
kubectl scale deployment argocd-repo-server --replicas=1 -n argocd
kubectl scale deployment argocd-application-controller --replicas=1 -n argocd

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=5m

# Scale up application (or let ArgoCD do it)
kubectl scale deployment mongodb --replicas=1 -n three-tier
kubectl scale deployment api --replicas=2 -n three-tier
kubectl scale deployment frontend --replicas=1 -n three-tier

# Verify
kubectl get pods -n three-tier -w
```

### Step 6: Recreate Ingress (if deleted) (2 minutes)

```bash
# Reapply ingress
kubectl apply -f Kubernetes-Manifests-file/ingress.yaml

# Wait for ALB to be provisioned (takes 2-3 minutes)
kubectl get ingress -n three-tier -w

# Get new ALB DNS
ALB_DNS=$(kubectl get ingress mainlb -n three-tier -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "New ALB DNS: $ALB_DNS"
```

### Step 7: Update Frontend Environment Variable (2 minutes)

```bash
# Update frontend deployment with new ALB DNS
kubectl set env deployment/frontend -n three-tier REACT_APP_BACKEND_URL="http://$ALB_DNS/api/tasks"

# Verify
kubectl get pods -n three-tier | grep frontend
```

### Step 8: Verify Everything is Working (2 minutes)

```bash
# Check all pods
kubectl get pods -n three-tier
kubectl get pods -n argocd
kubectl get pods -n monitoring

# Check services
kubectl get svc -n three-tier

# Test application
echo "Access your app at: http://$ALB_DNS"

# Test backend health
curl http://$ALB_DNS/healthz

# Access Jenkins (remember new IP!)
echo "Jenkins URL: http://$NEW_IP:8080"
```

---

## 📋 Quick Command Cheat Sheet

### **Shutdown (Copy & Paste - Run in Order)**

```bash
# ======= SHUTDOWN SEQUENCE =======

# 1. Backup MongoDB (if needed)
echo "Step 1: Backup MongoDB..."
kubectl exec -n three-tier deployment/mongodb -- mongodump --out /backup --archive=/backup/mongodb-backup-$(date +%Y%m%d).archive

# 2. Scale down workloads
echo "Step 2: Scaling down workloads..."
kubectl scale deployment frontend --replicas=0 -n three-tier
kubectl scale deployment api --replicas=0 -n three-tier
kubectl scale deployment mongodb --replicas=0 -n three-tier
kubectl scale deployment argocd-server --replicas=0 -n argocd
kubectl scale deployment argocd-repo-server --replicas=0 -n argocd
kubectl scale statefulset prometheus-kube-prometheus-prometheus --replicas=0 -n monitoring
kubectl scale deployment prometheus-grafana --replicas=0 -n monitoring

# 3. Delete node group (BIGGEST SAVINGS!)
echo "Step 3: Deleting EKS node group..."
eksctl get nodegroup --cluster three-tier-cluster --region us-east-1
# Copy the node group name from output above, then run:
# eksctl delete nodegroup --cluster=three-tier-cluster --name=<NODEGROUP-NAME> --region us-east-1

# 4. Stop Jenkins EC2
echo "Step 4: Stopping Jenkins EC2..."
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=jenkins-server" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].InstanceId" --output text --region us-east-1)
aws ec2 stop-instances --instance-ids $INSTANCE_ID --region us-east-1

echo "✅ Shutdown complete! Estimated daily savings: $10-12"
```

### **Startup (Copy & Paste - Run in Order)**

```bash
# ======= STARTUP SEQUENCE =======

# 1. Start Jenkins EC2
echo "Step 1: Starting Jenkins EC2..."
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=jenkins-server" "Name=instance-state-name,Values=stopped" --query "Reservations[*].Instances[*].InstanceId" --output text --region us-east-1)
aws ec2 start-instances --instance-ids $INSTANCE_ID --region us-east-1
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region us-east-1
NEW_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[*].Instances[*].PublicIpAddress" --output text --region us-east-1)
echo "✅ Jenkins started! New IP: $NEW_IP"
echo "Access at: http://$NEW_IP:8080"

# 2. Recreate node group
echo "Step 2: Creating EKS node group (takes 5-10 minutes)..."
eksctl create nodegroup --cluster=three-tier-cluster --region=us-east-1 --name=three-tier-nodes --node-type=t2.medium --nodes=2 --nodes-min=1 --nodes-max=3 --managed

# 3. Update kubeconfig
echo "Step 3: Updating kubeconfig..."
aws eks update-kubeconfig --name three-tier-cluster --region us-east-1
kubectl get nodes

# 4. Recreate ECR secret
echo "Step 4: Recreating ECR secret..."
kubectl delete secret ecr-registry-secret -n three-tier 2>/dev/null
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --namespace=three-tier

# 5. Scale up applications
echo "Step 5: Scaling up applications..."
kubectl scale statefulset prometheus-kube-prometheus-prometheus --replicas=1 -n monitoring
kubectl scale deployment prometheus-grafana --replicas=1 -n monitoring
kubectl scale deployment argocd-server --replicas=1 -n argocd
kubectl scale deployment argocd-repo-server --replicas=1 -n argocd
kubectl scale deployment argocd-application-controller --replicas=1 -n argocd
sleep 30
kubectl scale deployment mongodb --replicas=1 -n three-tier
kubectl scale deployment api --replicas=2 -n three-tier
kubectl scale deployment frontend --replicas=1 -n three-tier

# 6. Get ALB DNS
echo "Step 6: Getting ALB DNS..."
sleep 60
ALB_DNS=$(kubectl get ingress mainlb -n three-tier -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ALB DNS: $ALB_DNS"

# 7. Update frontend env
echo "Step 7: Updating frontend with ALB DNS..."
kubectl set env deployment/frontend -n three-tier REACT_APP_BACKEND_URL="http://$ALB_DNS/api/tasks"

# 8. Verify
echo "Step 8: Verifying everything..."
kubectl get pods -n three-tier
echo "✅ Startup complete!"
echo "Application URL: http://$ALB_DNS"
echo "Jenkins URL: http://$NEW_IP:8080"
```

---

## 🎯 Alternative: Even More Aggressive Cost Savings

### Option 1: Delete Entire EKS Cluster (Saves ~$4/day additional)

**⚠️ WARNING:** More setup time required next day

```bash
# Shutdown
eksctl delete cluster --name three-tier-cluster --region us-east-1

# Next day - Recreate cluster (15-20 minutes)
eksctl create cluster \
  --name three-tier-cluster \
  --region us-east-1 \
  --node-type t2.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3

# Then follow all startup steps from Phase 2
```

### Option 2: Terminate Jenkins EC2, Use Terraform to Recreate

```bash
# Shutdown
terraform destroy -var-file=variables.tfvars -target=aws_instance.ec2

# Next day (5-10 minutes)
terraform apply -var-file=variables.tfvars -target=aws_instance.ec2
```

---

## 📊 Cost Comparison

| Scenario | Daily Cost | Monthly Cost | Savings |
|----------|-----------|--------------|---------|
| **Always Running** | $14-18 | $420-540 | - |
| **Stopped Nights (16hrs)** | $9-12 | $270-360 | $150-180/mo |
| **Stopped Nights + Weekends** | $6-8 | $180-240 | $240-300/mo |
| **Completely Deleted** | $2-3 | $60-90 | $360-450/mo |

---

## ⚠️ Important Notes

1. **Jenkins IP Changes:** Every time you stop/start EC2, the public IP changes. Update:
   - GitHub webhook URL
   - Your browser bookmarks
   - Any hardcoded references

2. **ALB DNS Persists:** Load Balancer DNS usually stays the same unless you delete it

3. **Data Persistence:** 
   - EBS volumes are NOT deleted when stopping instances
   - MongoDB data is safe in PersistentVolume
   - ECR images remain available

4. **Startup Time:** Plan for 15-20 minutes total startup time

5. **Node Group Names:** Use `eksctl get nodegroup` to find exact names

6. **Region Consistency:** Always use `--region us-east-1` (or your region)

---

## 🔧 Automation Scripts (Optional)

Create these scripts for even easier management:

**shutdown.sh:**
```bash
#!/bin/bash
# Add all shutdown commands here
```

**startup.sh:**
```bash
#!/bin/bash
# Add all startup commands here
```

---

## 📞 Support

If you encounter issues:
1. Check AWS Console for resource states
2. Verify kubectl context: `kubectl config current-context`
3. Check CloudFormation stacks for EKS resources
4. Review AWS CloudWatch logs

---

**Remember:** The biggest savings come from deleting/stopping the node group! 💰

**Last Updated:** November 17, 2025
