# EKS Node Group Recreation Guide

**Purpose:** Step-by-step guide to recreate EKS node group after deletion  
**Time Required:** 5-10 minutes  
**Difficulty:** Easy (Console method requires no technical knowledge)

---

## 📋 Prerequisites

Before you delete your node group, you **MUST** save the following information:

### **Information Checklist:**

| Item | How to Find | Your Value (Fill This In!) |
|------|-------------|---------------------------|
| **Cluster Name** | EKS Console → Clusters | three-tier-cluster |
| **Node Group Name** | EKS Console → Compute tab | ng-960b346f |
| **Subnets** | Node Group Details → Networking | __________________ |
| **Node IAM Role ARN** | Node Group Details → Details tab | __________________ |
| **Instance Type** | Node Group Details → Details tab | t2.medium |
| **Disk Size** | Node Group Details → Details tab | 20 GB |
| **Desired Size** | Node Group Details → Details tab | 2 |
| **Minimum Size** | Node Group Details → Details tab | 1 |
| **Maximum Size** | Node Group Details → Details tab | 3 |

---

## 📸 Step 1: Save Node Group Configuration

### **1.1 Navigate to Node Group:**

1. Open **AWS Console** → **EKS** service
2. Click on **three-tier-cluster**
3. Go to **Compute** tab
4. Click on your node group name (e.g., `ng-960b346f`)

### **1.2 Screenshot These Pages:**

**Details Tab:**
- Node IAM role ARN (e.g., `arn:aws:iam::296062548155:role/eksctl-Three-Tier-K8s-EKS-Cluster-NodeInstanceRole-xxxxx`)
- Instance type: `t2.medium`
- Disk size: `20 GiB`
- AMI type: `AL2_x86_64`

**Scaling Configuration Tab:**
- Desired size: `2`
- Minimum size: `1`
- Maximum size: `3`

**Networking Tab:**
- Subnets (usually 2-3 subnets):
  - Example: `subnet-0aa439b4ddafcca10` (us-east-1a)
  - Example: `subnet-0b95df318219145ca` (us-east-1b)
  - Example: `subnet-0ccca36474902829a` (us-east-1c)

**💡 TIP:** Take screenshots or write these down!

---

## 🔄 Step 2: Recreate Node Group

### **Method A: AWS Console (Recommended - No CLI Required)**

#### **2.1 Start Creation:**

1. **AWS Console** → **EKS** → **three-tier-cluster**
2. Go to **Compute** tab
3. Click **"Add node group"** button

#### **2.2 Configure Node Group (Page 1):**

**Name and role:**
- **Name:** `ng-960b346f` (or choose new name like `three-tier-nodes-v2`)
- **Node IAM role:** 
  - Select from dropdown: `eksctl-Three-Tier-K8s-EKS-Cluster-NodeInstanceRole-xxxxx`
  - This is the role ARN you saved earlier
  - ⚠️ If you don't see your role, check IAM Console → Roles to verify it exists
- **Tags:** (Optional) Add any tags
- Click **Next**

**📸 Screenshot Recommended**

---

#### **2.3 Set Compute Configuration (Page 2):**

**AMI type:**
- Select: **Amazon Linux 2 (AL2_x86_64)**

**Capacity type:**
- Select: **On-Demand**

**Instance types:**
- Click **Add instance type**
- Select: **t2.medium**
- Remove any other instance types

**Disk size:**
- Enter: **20** GiB

**Update strategy:**
- Leave default (Rolling update)

Click **Next**

**📸 Screenshot Recommended**

---

#### **2.4 Set Scaling Configuration (Page 3):**

**Node Group scaling configuration:**
- **Desired size:** `2`
- **Minimum size:** `1`
- **Maximum size:** `3`

**Node Group update configuration:**
- Leave defaults

Click **Next**

**📸 Screenshot Recommended**

---

#### **2.5 Specify Networking (Page 4):**

**Subnets:**
- ✅ Check the **SAME subnets** you saved earlier
- Usually 2-3 subnets across different availability zones
- Example:
  - ✅ subnet-0aa439b4ddafcca10 (us-east-1a)
  - ✅ subnet-0b95df318219145ca (us-east-1b)
  - ✅ subnet-0ccca36474902829a (us-east-1c)

**Configure remote access:**
- ❌ Leave **unchecked** (unless you need SSH access to nodes)

**Security groups:**
- Leave **default** (will auto-configure)

Click **Next**

**📸 Screenshot Recommended**

---

#### **2.6 Review and Create (Page 5):**

**Review all settings:**
- Node group name: ✅
- IAM role: ✅
- Instance type: t2.medium ✅
- Scaling: 2/1/3 ✅
- Subnets: ✅

**Create the node group:**
- Click **Create**

**Wait for creation:**
- Status will show: **Creating** → **Active**
- Takes approximately **5-10 minutes**
- ☕ Good time for a coffee break!

---

### **Method B: AWS CLI (PowerShell)**

**Prerequisites:**
- AWS CLI configured
- You have saved subnet IDs and IAM role ARN

```powershell
# Set your variables (replace with your saved values)
$CLUSTER_NAME = "three-tier-cluster"
$NODEGROUP_NAME = "ng-960b346f-new"
$NODE_ROLE_ARN = "arn:aws:iam::296062548155:role/eksctl-Three-Tier-K8s-EKS-Cluster-NodeInstanceRole-xxxxx"
$SUBNET_1 = "subnet-0aa439b4ddafcca10"
$SUBNET_2 = "subnet-0b95df318219145ca"
$SUBNET_3 = "subnet-0ccca36474902829a"

# Create node group
aws eks create-nodegroup `
  --cluster-name $CLUSTER_NAME `
  --nodegroup-name $NODEGROUP_NAME `
  --scaling-config minSize=1,maxSize=3,desiredSize=2 `
  --disk-size 20 `
  --subnets $SUBNET_1 $SUBNET_2 $SUBNET_3 `
  --instance-types t2.medium `
  --node-role $NODE_ROLE_ARN `
  --region us-east-1

# Check creation status
aws eks describe-nodegroup `
  --cluster-name $CLUSTER_NAME `
  --nodegroup-name $NODEGROUP_NAME `
  --region us-east-1 `
  --query "nodegroup.status"

# Wait for it to become ACTIVE (5-10 minutes)
```

---

### **Method C: Using eksctl (If Installed)**

```bash
# Simple command - eksctl will auto-configure most settings
eksctl create nodegroup \
  --cluster=three-tier-cluster \
  --region=us-east-1 \
  --name=three-tier-nodes \
  --node-type=t2.medium \
  --nodes=2 \
  --nodes-min=1 \
  --nodes-max=3 \
  --managed

# This will:
# - Auto-discover VPC and subnets
# - Create IAM role if needed
# - Configure security groups
# - Takes 5-10 minutes
```

---

## ✅ Step 3: Verify Node Group Creation

### **3.1 Check in AWS Console:**

1. **EKS Console** → **three-tier-cluster** → **Compute** tab
2. Node group status should be: **Active** ✅
3. **Nodes** section should show: **2** nodes

### **3.2 Check in Kubernetes:**

Open PowerShell and run:

```powershell
# Update kubeconfig (if needed)
aws eks update-kubeconfig --name three-tier-cluster --region us-east-1

# Check nodes
kubectl get nodes
```

**Expected Output:**
```
NAME                             STATUS   ROLES    AGE   VERSION
ip-192-168-22-193.ec2.internal   Ready    <none>   5m    v1.32.9-eks-c39b1d0
ip-192-168-36-77.ec2.internal    Ready    <none>   5m    v1.32.9-eks-c39b1d0
```

**✅ Success Indicators:**
- 2 nodes visible
- STATUS = **Ready**
- AGE shows recent creation time

### **3.3 Check Node Details:**

```powershell
# Get detailed node info
kubectl describe nodes

# Check node resources
kubectl top nodes
```

---

## 🚀 Step 4: Next Steps After Node Recreation

Once nodes are Ready, you need to:

### **4.1 Recreate ECR Secret:**

```powershell
# Delete old secret (if exists)
kubectl delete secret ecr-registry-secret -n three-tier

# Create new secret with fresh token
kubectl create secret docker-registry ecr-registry-secret `
  --docker-server=296062548155.dkr.ecr.us-east-1.amazonaws.com `
  --docker-username=AWS `
  --docker-password=$(aws ecr get-login-password --region us-east-1) `
  --namespace=three-tier

# Verify
kubectl get secret ecr-registry-secret -n three-tier
```

### **4.2 Scale Up Applications:**

```powershell
# Scale up in correct order
kubectl scale deployment mongodb --replicas=1 -n three-tier
sleep 30  # Wait for database

kubectl scale deployment api --replicas=2 -n three-tier
sleep 20

kubectl scale deployment frontend --replicas=1 -n three-tier

# Verify all pods are running
kubectl get pods -n three-tier -w
```

### **4.3 Scale Up Monitoring (Optional):**

```powershell
kubectl scale statefulset prometheus-kube-prometheus-prometheus --replicas=1 -n monitoring
kubectl scale deployment prometheus-grafana --replicas=1 -n monitoring
```

### **4.4 Scale Up ArgoCD (Optional):**

```powershell
kubectl scale deployment argocd-server --replicas=1 -n argocd
kubectl scale deployment argocd-repo-server --replicas=1 -n argocd
kubectl scale deployment argocd-application-controller --replicas=1 -n argocd
```

---

## ⚠️ Troubleshooting

### **Problem: IAM Role Not Found in Dropdown**

**Solution:**
1. Go to **IAM Console** → **Roles**
2. Search for: `eksctl-Three-Tier-K8s-EKS-Cluster-NodeInstanceRole`
3. Copy the full ARN
4. Use AWS CLI method instead of console

---

### **Problem: Nodes Stay in NotReady State**

**Check:**
```powershell
kubectl describe node <node-name>
kubectl get pods -n kube-system
```

**Common causes:**
- CNI plugin not running
- Security group misconfigured
- Subnet has no internet access

**Solution:** Wait 5 more minutes, nodes often take time to initialize

---

### **Problem: Node Group Creation Fails**

**Common reasons:**
1. **Insufficient subnet IPs** - Use different subnets
2. **IAM role missing permissions** - Verify role has required policies
3. **Service limit reached** - Check EC2 service limits

**Check CloudFormation:**
- **CloudFormation Console** → Check for failed stacks
- Look for error messages

---

### **Problem: Can't Find Saved Subnets**

**Find them manually:**
1. **VPC Console** → **Subnets**
2. Filter by VPC used by EKS cluster
3. Look for subnets in multiple availability zones
4. Use subnets from your cluster's VPC

---

## 📊 Cost Impact

| Action | Cost When Running | Cost When Deleted | Savings |
|--------|------------------|-------------------|---------|
| **Node Group (2x t2.medium)** | ~$0.09/hr ($2.16/day) | $0 | $2.16/day |
| **Monthly Savings** | - | - | ~$65/month |

---

## 🎯 Best Practices

✅ **Always save node group configuration before deletion**  
✅ **Take screenshots of all configuration pages**  
✅ **Use same subnets for consistency**  
✅ **Keep IAM role name noted**  
✅ **Verify nodes are Ready before scaling applications**  
✅ **Recreate ECR secret after node recreation**  

---

## 📝 Quick Checklist

**Before Deleting:**
- [ ] Screenshot node group Details page
- [ ] Note down subnet IDs (2-3 subnets)
- [ ] Copy IAM role ARN
- [ ] Verify instance type (t2.medium)
- [ ] Note scaling config (2/1/3)

**During Recreation:**
- [ ] Use same IAM role
- [ ] Use same subnets
- [ ] Use same instance type
- [ ] Use same scaling config
- [ ] Wait for "Active" status

**After Recreation:**
- [ ] Verify `kubectl get nodes` shows 2 Ready nodes
- [ ] Recreate ECR secret
- [ ] Scale up applications
- [ ] Test application access

---

## 🆘 Need Help?

If you encounter issues:

1. **Check AWS Console:**
   - EKS → Clusters → three-tier-cluster → Compute tab
   - Look for error messages

2. **Check Kubernetes:**
   ```powershell
   kubectl get nodes
   kubectl get pods -n kube-system
   kubectl describe node <node-name>
   ```

3. **Check CloudFormation:**
   - CloudFormation Console → Stacks
   - Look for failed node group stack

4. **AWS Support:**
   - Check service health dashboard
   - Review CloudWatch logs

---

**Last Updated:** November 17, 2025  
**Version:** 1.0

**Remember:** Node group recreation is straightforward - just save your config before deleting! 🚀
