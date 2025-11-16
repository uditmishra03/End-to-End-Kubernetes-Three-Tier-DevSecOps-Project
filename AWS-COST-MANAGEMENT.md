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

**⚠️ This is the biggest cost saver!**

```bash
# List node groups
eksctl get nodegroup --cluster three-tier-cluster --region us-east-1

# Delete the node group (saves ~$2.16/day)
eksctl delete nodegroup --cluster=three-tier-cluster --name=<nodegroup-name> --region us-east-1
```

**Alternative: Scale to 0 nodes**
```bash
eksctl scale nodegroup --cluster=three-tier-cluster --name=<nodegroup-name> --nodes=0 --region us-east-1
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

# Wait for nodes to be ready
kubectl get nodes -w
```

**Or scale back up:**
```bash
eksctl scale nodegroup --cluster=three-tier-cluster --name=<nodegroup-name> --nodes=2 --region us-east-1
```

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
