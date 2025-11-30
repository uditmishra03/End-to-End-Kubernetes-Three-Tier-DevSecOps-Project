# 🚀 Getting Started - Complete Deployment Guide

## Overview

This guide provides a **step-by-step deployment order** for setting up the entire Three-Tier DevSecOps Kubernetes project from scratch. Follow these steps sequentially to deploy the complete infrastructure and application.

**Total Setup Time:** ~4-6 hours (depending on AWS resource provisioning)

---

## 🎬 Demo Videos

Before you begin, watch these walkthrough videos to see the complete project in action:

1. **📹 [Complete Architecture Walkthrough](https://youtu.be/UDUG4bSSoV0?si=nEWenIlAgi_nv0yh)** - Full system architecture overview and component walkthrough
2. **📹 [Three-Tier Project | Backend Application Walkthrough - Complete CI/CD Pipeline](https://youtu.be/KwXfFxuK1MM)** - Backend CI/CD demonstration with Jenkins, security scanning, and automated deployment
3. **📹 [Frontend CI/CD Pipeline Demo](https://youtu.be/W7wGFY9dyYU?si=96heJTQO0ld49pRq)** *(No audio)* - Frontend code changes triggering zero-downtime deployments

These videos demonstrate the exact flow you'll be implementing in this guide!

---

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- ✅ AWS Account with appropriate permissions
- ✅ AWS CLI installed and configured
- ✅ Terraform installed (>= 1.0)
- ✅ kubectl installed
- ✅ eksctl installed
- ✅ Git installed
- ✅ Domain name (optional, for custom domains)
- ✅ GitHub account with personal access token

**Detailed prerequisites:** See [DOCUMENTATION.md - Section 4](./DOCUMENTATION.md#4-prerequisites-and-initial-setup)

---

## 🎯 Deployment Order - Step by Step

### **Step 1: Clone Repositories**

Clone all three required repositories:

```bash
# Main infrastructure repository
git clone https://github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git
cd End-to-End-Kubernetes-Three-Tier-DevSecOps-Project

# Backend repository (three-tier-be)
git clone https://github.com/uditmishra03/three-tier-be.git

# Frontend repository (three-tier-fe)
git clone https://github.com/uditmishra03/three-tier-fe.git
```

**Why:** The project uses a three-repository structure for infrastructure, backend, and frontend separation.

---

### **Step 2: Set Up Jenkins Infrastructure**

Deploy Jenkins server and supporting infrastructure using Terraform.

```bash
cd Jenkins-Server-TF

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply -auto-approve
```

**What gets created:**
- EC2 instance (t2.large) for Jenkins
- Security groups
- IAM roles and policies
- ECR repositories (backend, frontend, database)
- S3 bucket for Terraform state

**Time:** ~10-15 minutes

**Detailed instructions:** [DOCUMENTATION.md - Section 5](./DOCUMENTATION.md#5-jenkins-infrastructure-setup-with-terraform)

**Verification:**
```bash
# Get Jenkins EC2 public IP
terraform output jenkins_public_ip

# Access Jenkins UI
http://<JENKINS_PUBLIC_IP>:8080
```

---

### **Step 3: Configure Jenkins**

Access Jenkins and complete initial configuration.

#### 3.1 Install Required Plugins

Navigate to **Manage Jenkins → Plugin Manager** and install:
- Docker Pipeline
- SonarQube Scanner
- NodeJS
- OWASP Dependency-Check
- Eclipse Temurin installer

#### 3.2 Configure Global Tools

**Manage Jenkins → Tools:**
- JDK: Install JDK 17
- NodeJS: Install Node 16
- SonarQube Scanner: Latest version
- Docker: Add Docker installation

#### 3.3 Set Up Credentials

**Manage Jenkins → Credentials:**
- `github`: GitHub Personal Access Token
- `sonarqube`: SonarQube authentication token
- `docker-cred`: AWS ECR credentials (handled by IAM role)

#### 3.4 Configure SonarQube

1. Access SonarQube: `http://<JENKINS_IP>:9000`
2. Default login: `admin/admin`
3. Generate authentication token
4. Configure SonarQube server in Jenkins:
   - **Manage Jenkins → Configure System → SonarQube servers**
   - Add server URL and token

#### 3.5 Set Up GitHub Webhooks

For each repository (main, backend, frontend):
1. Go to **Repository → Settings → Webhooks**
2. Add webhook: `http://<JENKINS_IP>:8080/github-webhook/`
3. Content type: `application/json`
4. Events: Push events

**Time:** ~30-45 minutes

**Detailed instructions:** [DOCUMENTATION.md - Section 6](./DOCUMENTATION.md#6-jenkins-configuration-and-pipeline-setup)

---

### **Step 4: Deploy EKS Cluster**

Create the Kubernetes cluster using eksctl.

```bash
cd k8s-infrastructure

# Create EKS cluster
eksctl create cluster -f eks-cluster.yaml
```

**Cluster Configuration:**
- Name: three-tier-eks-cluster
- Region: us-east-1
- Node group: 2-3 t3.medium instances
- Version: 1.27+

**Time:** ~20-25 minutes

**Detailed instructions:** [DOCUMENTATION.md - Section 7](./DOCUMENTATION.md#7-eks-cluster-setup-and-configuration)

**Verification:**
```bash
# Verify cluster access
kubectl get nodes

# Expected output: 2-3 nodes in Ready state
```

---

### **Step 5: Set Up AWS Load Balancer Controller**

Install the AWS Load Balancer Controller for Ingress support.

```bash
# Create IAM OIDC provider
eksctl utils associate-iam-oidc-provider \
    --region us-east-1 \
    --cluster three-tier-eks-cluster \
    --approve

# Create IAM policy
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.0/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json

# Create service account
eksctl create iamserviceaccount \
    --cluster=three-tier-eks-cluster \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::<ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
    --approve

# Install using Helm
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=three-tier-eks-cluster \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller
```

**Time:** ~10 minutes

**Detailed instructions:** [DOCUMENTATION.md - Section 8](./DOCUMENTATION.md#8-application-deployment-on-eks)

---

### **Step 6: Deploy MongoDB Database**

Deploy the MongoDB database to the cluster.

```bash
cd k8s-infrastructure/database

# Apply database manifests
kubectl apply -f namespace.yaml
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

**Verification:**
```bash
kubectl get pods -n database
# Wait for mongo pod to be Running
```

**Time:** ~5 minutes

---

### **Step 7: Create and Run Jenkins Pipelines**

Set up CI/CD pipelines for backend and frontend applications.

#### 7.1 Backend Pipeline

1. **Jenkins → New Item → Pipeline**
2. Name: `three-tier-backend`
3. Configure:
   - **Build Triggers:** GitHub hook trigger for GITScm polling
   - **Pipeline:** Pipeline script from SCM
   - **SCM:** Git
   - **Repository URL:** `https://github.com/uditmishra03/three-tier-be.git`
   - **Script Path:** `Jenkinsfile`
4. **Save and Build**

#### 7.2 Frontend Pipeline

1. **Jenkins → New Item → Pipeline**
2. Name: `three-tier-frontend`
3. Configure:
   - **Build Triggers:** GitHub hook trigger for GITScm polling
   - **Pipeline:** Pipeline script from SCM
   - **SCM:** Git
   - **Repository URL:** `https://github.com/uditmishra03/three-tier-fe.git`
   - **Script Path:** `Jenkinsfile`
4. **Save and Build**

**Pipeline Stages:**
1. **Sonarqube Analysis & Quality Check** (Combined: Code quality analysis + quality gate)
2. **Trivy File Scan** (File system security scan)
3. **Docker Build & Push with Buildx** (Combined: Build image with YYYYMMDD-BUILD format + push to ECR)
4. **TRIVY Image Scan** (Container security scan)

**Time:** ~30-50 seconds per pipeline (Backend ~31s, Frontend ~51s)

**Note:** Multibranch Pipelines auto-checkout code, so no explicit checkout stage is needed.

**Detailed instructions:** [DOCUMENTATION.md - Section 9](./DOCUMENTATION.md#9-cicd-pipeline-implementation)

**Verification:**
```bash
# Check ECR repositories
aws ecr describe-repositories

# List images in backend repo
aws ecr list-images --repository-name three-tier-backend

# List images in frontend repo
aws ecr list-images --repository-name three-tier-frontend
```

---

### **Step 8: Deploy Initial Kubernetes Manifests**

Deploy the initial application manifests (before ArgoCD setup).

#### 8.1 Backend Deployment

```bash
cd three-tier-be/manifests

# Update deployment.yaml with correct ECR image URI
# Format: <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/three-tier-backend:<TAG>

kubectl apply -k .
```

#### 8.2 Frontend Deployment

```bash
cd three-tier-fe/manifests

# Update deployment.yaml with correct ECR image URI
# Format: <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/three-tier-frontend:<TAG>

kubectl apply -k .
```

**Verification:**
```bash
kubectl get pods -n three-tier
# All pods should be Running
```

**Time:** ~10 minutes

**Detailed instructions:** [DOCUMENTATION.md - Section 10](./DOCUMENTATION.md#10-kubernetes-deployments-and-services)

---

### **Step 9: Install and Configure ArgoCD**

Set up GitOps with ArgoCD for continuous deployment.

#### 9.1 Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

#### 9.2 Access ArgoCD UI

```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8081:443

# Access UI at: https://localhost:8081
# Username: admin
# Password: <from above command>
```

#### 9.3 Install ArgoCD Image Updater

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
```

#### 9.4 Configure ECR Access for Image Updater

```bash
cd argocd-image-updater-config

# Run configuration scripts
./bootstrap-irsa.sh
./configure-deployment.sh

# Apply configurations
kubectl apply -f ecr-credentials-helper.yaml
kubectl apply -f serviceaccount.yaml
kubectl apply -f registries-configmap.yaml
```

#### 9.5 Create ArgoCD Applications

```bash
cd argocd-apps

# Deploy all applications
kubectl apply -f backend-app.yaml
kubectl apply -f frontend-app.yaml
kubectl apply -f database-app.yaml
kubectl apply -f ingress-app.yaml
```

**ArgoCD Image Updater Configuration:**
- Monitors ECR repositories for new images
- Uses semantic version regex: `^[0-9-]+$`
- Automatically updates deployments when new images are pushed
- No git write-back - direct cluster updates only

**Time:** ~20-30 minutes

**Detailed instructions:** [DOCUMENTATION.md - Section 11](./DOCUMENTATION.md#11-argocd-and-gitops-setup)

**Verification:**
```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# All applications should be "Healthy" and "Synced"

# Check Image Updater logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater
```

---

### **Step 10: Set Up Monitoring Stack**

Deploy Prometheus and Grafana for observability.

#### 10.1 Install Prometheus using Helm

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus stack (installs to monitoring namespace)
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring
```

#### 10.2 Access Prometheus

**Via HTTPS (Shared ALB - Recommended):**
```bash
# Access Prometheus web UI
https://monitoring.tarang.cloud/prometheus

# Query metrics, view targets, alerts
```

**Or via Port Forward (Local Development):**
```bash
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# Access at: http://localhost:9090
```

#### 10.3 Access Grafana

**Via HTTPS (Shared ALB - Recommended):**
```bash
# Access Grafana dashboard
https://monitoring.tarang.cloud/grafana

# Default credentials:
# Username: admin
# Password: admin (configured in prometheus-values.yaml)
```

**Get Admin Password:**
```bash
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo

# Username: admin
# Password: <from above command>
```

**Or via Port Forward:**
```bash
kubectl port-forward -n default svc/stable-grafana 3000:80
# Access at: http://localhost:3000
```

#### 10.4 Configure Prometheus Data Source

Before importing dashboards:
1. **Login to Grafana**
2. **Go to Configuration → Data Sources**
3. **Add Prometheus data source:**
   - URL: `http://prometheus-operated:9090`
   - Click **Save & Test**

#### 10.5 Import Dashboard

In Grafana UI:
1. **Click + → Import**
2. **Import Dashboard ID: `315`** (Kubernetes cluster monitoring via Prometheus)
   - This is the primary dashboard used in this project
3. **Select Prometheus data source**
4. **Click Import**

**Alternative: Import from Repository**
- Pre-configured dashboard JSON is available at:
  - `assets/grafana_dashboard/Kubernetes cluster monitoring (via Prometheus)-1764256820704.json`
- To import: **+ → Import → Upload JSON file**

**Additional Recommended Dashboards (Optional):**
- `15760` - Kubernetes / Views / Global
- `15761` - Kubernetes / Views / Namespaces
- `15762` - Kubernetes / Views / Pods
- `6417` - Kubernetes Cluster Monitoring
- `13770` - Kubernetes Cluster (Prometheus)

#### 10.6 Configure Dashboard Variables

For imported dashboards to work correctly, configure these variables:

1. **Add `namespace` variable:**
   - Name: `namespace`
   - Type: Query
   - Data source: Prometheus
   - Query: `label_values(kube_pod_info, namespace)`
   - Multi-value: ✅
   - Include All: ✅

2. **Add `instance` variable (for node metrics):**
   - Name: `instance`
   - Type: Query
   - Data source: Prometheus
   - Query: `label_values(node_cpu_seconds_total, instance)`
   - Multi-value: ✅
   - Include All: ✅

3. **Add `node` variable (for cluster resources):**
   - Name: `node`
   - Type: Query
   - Data source: Prometheus
   - Query: `label_values(kube_node_info, node)`
   - Multi-value: ✅
   - Include All: ✅

#### 10.7 Fix Panel Queries (If Showing "No Data")

Some imported dashboards may need query updates to match kube-prometheus-stack metrics:

**CPU Usage (1m avg):**
```promql
100 - avg by(instance)(rate(node_cpu_seconds_total{mode="idle", instance=~"$instance"}[1m])) * 100
```

**Memory Usage (percent):**
```promql
(1 - avg by(instance)(node_memory_MemAvailable_bytes{instance=~"$instance"} / node_memory_MemTotal_bytes{instance=~"$instance"})) * 100
```

**Pod Count by Namespace:**
```promql
count by(namespace) (kube_pod_info{namespace=~"$namespace"})
```

**Deployment Count:**
```promql
count by(namespace) (kube_deployment_created{namespace=~"$namespace"})
```

#### 10.8 Use Pre-Configured Dashboard

The repository includes a pre-configured dashboard with all variables and queries optimized for kube-prometheus-stack:

**Dashboard Location:**
- `assets/grafana_dashboard/Kubernetes cluster monitoring (via Prometheus)-1764256820704.json`

**To Import:**
1. In Grafana, click **+ → Import → Upload JSON file**
2. Select the JSON file from `assets/grafana_dashboard/`
3. Choose Prometheus data source
4. Click Import

**What's Included:**
- ✅ All variables pre-configured (`namespace`, `instance`, `node`)
- ✅ All queries fixed for kube-prometheus-stack metrics
- ✅ Cluster resource panels (pods, deployments, services, ingresses)
- ✅ System metrics (CPU, memory, network, disk)
- ✅ Dashboard ID: 315 base configuration

**To Export Updated Dashboard:**
1. Dashboard settings (gear icon) → JSON Model
2. Copy JSON and save to `assets/grafana_dashboard/`
3. Commit to Git for version control

**Time:** ~15-20 minutes

**Detailed instructions:** [DOCUMENTATION.md - Section 12-13](./DOCUMENTATION.md#12-monitoring-with-prometheus)

---

### **Step 11: Set Up Ingress (Optional)**

Configure Ingress for external access with custom domain.

```bash
cd k8s-infrastructure/ingress

# Update ingress.yaml with your domain
# Apply ingress
kubectl apply -f ingress.yaml
```

**Get Load Balancer URL:**
```bash
kubectl get ingress -n three-tier

# Copy the ADDRESS field and create DNS A record pointing to it
```

**Time:** ~10 minutes

**Detailed instructions:** [DOCUMENTATION.md - Section 10](./DOCUMENTATION.md#10-kubernetes-deployments-and-services)

---

## ✅ Verification Checklist

After completing all steps, verify the following:

### Infrastructure
- [ ] Jenkins server is accessible on port 8080
- [ ] SonarQube is accessible on port 9000
- [ ] EKS cluster has 2-3 nodes in Ready state
- [ ] AWS Load Balancer Controller is running

### CI/CD Pipelines
- [ ] Backend pipeline completes successfully
- [ ] Frontend pipeline completes successfully
- [ ] Docker images are pushed to ECR
- [ ] Image tags follow YYYYMMDD-BUILD format

### Applications
- [ ] MongoDB pod is running in `database` namespace
- [ ] Backend pods are running in `three-tier` namespace
- [ ] Frontend pods are running in `three-tier` namespace
- [ ] All pods are in `Running` state with no restarts

### GitOps
- [ ] ArgoCD UI is accessible
- [ ] All ArgoCD applications are "Healthy" and "Synced"
- [ ] ArgoCD Image Updater is running and monitoring ECR
- [ ] Image Updater logs show no errors

### Monitoring
- [ ] Prometheus is scraping metrics
- [ ] Grafana dashboards display cluster metrics
- [ ] All targets are UP in Prometheus

### Networking
- [ ] Services are accessible within cluster
- [ ] Ingress (if configured) routes traffic correctly
- [ ] Load balancer is provisioned

---

## 🔄 GitOps Workflow Overview

Once everything is set up, your automated workflow operates as follows:

```
1. Developer pushes code to GitHub (backend or frontend repo)
   ↓
2. GitHub webhook triggers Jenkins pipeline
   ↓
3. Jenkins pipeline:
   - Runs SonarQube analysis
   - Checks quality gate
   - Runs Trivy security scans
   - Builds Docker image with YYYYMMDD-BUILD tag
   - Pushes image to AWS ECR
   ↓
4. ArgoCD Image Updater (running every 2 minutes):
   - Detects new image in ECR using semantic version regex
   - Automatically updates deployment in EKS cluster
   - No git write-back - direct cluster updates only
   ↓
5. Application is automatically deployed with zero downtime
```

**Key Point:** Jenkins does NOT update Kubernetes manifests or push to Git. ArgoCD Image Updater monitors ECR directly and updates the cluster.

---

## 🛠️ Common Post-Deployment Tasks

### Test the Application

```bash
# Get frontend service URL
kubectl get svc -n three-tier frontend-service

# If using LoadBalancer type
curl http://<EXTERNAL-IP>

# If using NodePort
curl http://<NODE-IP>:<NODE-PORT>
```

### Trigger a New Deployment

```bash
# Make a code change in backend or frontend repo
git add .
git commit -m "Update feature"
git push origin master

# Watch Jenkins build
# Jenkins will build and push new image to ECR
# ArgoCD Image Updater will detect and deploy automatically
```

### View Application Logs

```bash
# Backend logs
kubectl logs -n three-tier -l app=backend -f

# Frontend logs
kubectl logs -n three-tier -l app=frontend -f

# Database logs
kubectl logs -n database -l app=mongo -f
```

### Scale Applications

```bash
# Scale backend
kubectl scale deployment backend -n three-tier --replicas=3

# Scale frontend
kubectl scale deployment frontend -n three-tier --replicas=3
```

---

## 📊 Project Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           DEVELOPER WORKFLOW                             │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    Code Push to GitHub (main/three-tier-be/three-tier-fe)
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          JENKINS CI PIPELINE                             │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  1. Checkout  →  2. SonarQube  →  3. Quality Gate               │  │
│  │  4. Build     →  5. Trivy Scan →  6. Push to ECR                │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                         Push Image (YYYYMMDD-BUILD)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                            AWS ECR REGISTRIES                            │
│         backend-repo    │    frontend-repo    │    database-repo        │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ArgoCD Image Updater monitors ECR (every 2 min)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      ARGOCD GITOPS (Image Updater)                       │
│  Detects new image → Updates deployment → Direct cluster deployment     │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                         Automatic Deployment
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          EKS CLUSTER (AWS)                               │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐           │
│  │  Frontend      │  │  Backend       │  │  MongoDB       │           │
│  │  (React)       │  │  (Node.js)     │  │  (Database)    │           │
│  └────────────────┘  └────────────────┘  └────────────────┘           │
│                                                                          │
│  Monitored by: Prometheus + Grafana                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

**Visual Diagrams:**
- [System Architecture Diagram (draw.io)](../assets/system-architecture.drawio)
- [System Architecture Diagram (Mermaid)](../assets/system-architecture.mmd)

---

## 🆘 Troubleshooting

### Jenkins Issues
- **Cannot access Jenkins UI:** Check security group allows port 8080
- **Pipeline fails at SonarQube:** Verify SonarQube server URL and token
- **Docker push fails:** Check IAM role has ECR permissions

### EKS Issues
- **Nodes not joining cluster:** Check subnet configuration and security groups
- **Pods stuck in Pending:** Check node capacity and resource requests
- **Cannot access cluster:** Run `aws eks update-kubeconfig --name three-tier-eks-cluster --region us-east-1`

### ArgoCD Issues
- **Application OutOfSync:** Click "Sync" in ArgoCD UI
- **Image Updater not detecting new images:** Check ECR credentials and registry configuration
- **Application Degraded:** Check pod logs for errors

For detailed troubleshooting, see: [DOCUMENTATION.md - Section 14](./DOCUMENTATION.md#14-testing-and-validation)

---

## 🗑️ Infrastructure Cleanup and Teardown

This section provides a complete guide to properly destroy all AWS resources created by this project to avoid unexpected charges.

### 📌 Understanding the Infrastructure Stack

This project creates infrastructure using **three different tools**, which must be destroyed in reverse order:

| Tool | What It Manages | Destruction Method |
|------|----------------|-------------------|
| **kubectl/Helm** | K8s applications, services, ingress, ALB | `kubectl delete` / `helm uninstall` |
| **eksctl** | EKS cluster, node groups, CloudFormation stacks | `eksctl delete cluster` |
| **Terraform** | Jenkins EC2, VPC, ECR, IAM, Security Groups | `terraform destroy` |

**Why this order matters:**
1. K8s resources must be deleted first (to remove ALB, EBS volumes created by K8s)
2. EKS cluster must be deleted before Terraform (cluster may create dependencies)
3. Terraform destroys the base infrastructure last (VPC, Jenkins, ECR)

---

### ⚠️ Important Pre-Cleanup Considerations

**Before proceeding with cleanup:**
- ✅ Backup any important data (Grafana dashboards, Jenkins configurations, MongoDB data)
- ✅ Export environment variables or configurations you might need later
- ✅ Take note of any custom settings or modifications
- ✅ Ensure you have committed and pushed any code changes to GitHub

**Resources that will be destroyed:**
- ✅ EKS Cluster (control plane + worker nodes) - **eksctl managed**
- ✅ Jenkins EC2 instance and EIP - **Terraform managed**
- ✅ VPC, subnets, security groups, route tables - **Terraform managed**
- ✅ ECR repositories and container images - **Terraform managed**
- ✅ Application Load Balancers (ALB) - **K8s/kubectl managed**
- ✅ EBS volumes (Jenkins, Prometheus, Grafana, MongoDB) - **Mixed (K8s + Terraform)**
- ✅ IAM roles and policies - **Mixed (eksctl + Terraform)**
- ✅ CloudWatch log groups - **Auto-created (manual cleanup if needed)**

---

### Step-by-Step Teardown Process

Follow these steps **in order** to avoid dependency issues and ensure complete cleanup.

---

#### **Step 1: Delete Kubernetes Applications and Services**

First, remove all applications and services from the EKS cluster. This ensures ALBs and other AWS resources created by Kubernetes controllers are properly cleaned up.

```bash
# Configure kubectl for your EKS cluster (if not already configured)
aws eks update-kubeconfig --name three-tier-eks-cluster --region us-east-1

# Delete ArgoCD applications (this removes all managed resources)
kubectl delete application -n argocd backend frontend database ingress --wait=true

# Delete Ingress resources (removes ALB)
kubectl delete ingress -n three-tier mainlb --wait=true
kubectl delete ingress -n monitoring monitoring-ingress --wait=true

# Delete monitoring stack
helm uninstall prometheus -n monitoring
helm uninstall grafana -n monitoring

# Delete ArgoCD
kubectl delete namespace argocd --wait=true

# Delete application namespace
kubectl delete namespace three-tier --wait=true

# Delete monitoring namespace
kubectl delete namespace monitoring --wait=true

# Verify ALB deletion (may take 2-5 minutes)
aws elbv2 describe-load-balancers --region us-east-1 | grep k8s-sharedalb
# Should return no results once fully deleted
```

**Wait Time:** 5-10 minutes for all resources to be deleted properly

**Troubleshooting:**
- If namespace stuck in `Terminating` state:
  ```bash
  kubectl get namespace <namespace> -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/<namespace>/finalize" -f -
  ```
- If ALB not deleted after 10 minutes, manually delete from AWS Console

---

#### **Step 2: Delete EKS Cluster**

Delete the EKS cluster and all associated node groups.

```bash
# List existing clusters
eksctl get cluster --region us-east-1

# Delete the cluster (this also deletes all node groups)
eksctl delete cluster --name three-tier-eks-cluster --region us-east-1 --wait

# Alternative: If you have a cluster config file
# eksctl delete cluster -f eks-cluster.yaml --wait
```

**Wait Time:** 15-20 minutes

**What gets deleted:**
- EKS control plane
- All node groups (EC2 instances)
- CloudFormation stacks created by eksctl
- IAM roles created by eksctl (eksctl-* roles)
- Security groups created by eksctl
- Launch templates

**Verify deletion:**
```bash
# Check if cluster is deleted
aws eks list-clusters --region us-east-1
# Should NOT show three-tier-eks-cluster

# Check CloudFormation stacks
aws cloudformation list-stacks --region us-east-1 --stack-status-filter DELETE_COMPLETE
# Should show eksctl-three-tier-eks-cluster-* stacks as DELETE_COMPLETE
```

**Troubleshooting:**
- If deletion fails with VPC dependency error:
  ```bash
  # Manually delete ENIs (Elastic Network Interfaces)
  aws ec2 describe-network-interfaces --region us-east-1 --filters "Name=vpc-id,Values=<VPC-ID>" --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text | xargs -n 1 aws ec2 delete-network-interface --region us-east-1 --network-interface-id
  
  # Then retry cluster deletion
  eksctl delete cluster --name three-tier-eks-cluster --region us-east-1 --wait
  ```

---

#### **Step 3: Delete ECR Repositories (Managed by Terraform)**

**⚠️ IMPORTANT:** If your ECR repositories were created by Terraform (in `Jenkins-Server-TF/ecr_repositories.tf`), **skip this step** - they will be automatically deleted in Step 4 when you run `terraform destroy`.

Only follow this step if you manually created ECR repositories outside of Terraform.

<details>
<summary>Click to expand: Manual ECR cleanup (only if NOT using Terraform for ECR)</summary>

```bash
# List ECR repositories
aws ecr describe-repositories --region us-east-1

# Delete all images in each repository first (repositories must be empty before deletion)
aws ecr batch-delete-image \
    --repository-name frontend \
    --region us-east-1 \
    --image-ids "$(aws ecr list-images --repository-name frontend --region us-east-1 --query 'imageIds[*]' --output json)" || true

aws ecr batch-delete-image \
    --repository-name backend \
    --region us-east-1 \
    --image-ids "$(aws ecr list-images --repository-name backend --region us-east-1 --query 'imageIds[*]' --output json)" || true

# Delete ECR repositories
aws ecr delete-repository --repository-name frontend --region us-east-1 --force
aws ecr delete-repository --repository-name backend --region us-east-1 --force

# Verify deletion
aws ecr describe-repositories --region us-east-1
# Should show empty list or not include frontend/backend repos
```

</details>

**For most users:** Skip to Step 4 - Terraform will handle ECR cleanup automatically.

---

#### **Step 4: Destroy Jenkins Infrastructure with Terraform** ⭐ **PRIMARY DESTRUCTION METHOD**

**This is the main destruction step.** Terraform will automatically destroy all infrastructure it created.

```bash
# Navigate to Terraform directory
cd End-to-End-Kubernetes-Three-Tier-DevSecOps-Project/Jenkins-Server-TF

# Verify Terraform state (see what will be destroyed)
terraform state list

# Review destruction plan
terraform plan -destroy -var-file=variables.tfvars

# Destroy all Terraform-managed infrastructure
terraform destroy -var-file=variables.tfvars
```

**Terraform will prompt for confirmation:**
```
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes    # Type 'yes' and press Enter
```

**What Terraform automatically destroys:**
- ✅ Jenkins EC2 instance (c6a.2xlarge or t2.2xlarge)
- ✅ Elastic IP (EIP) and EIP association
- ✅ VPC, subnets, internet gateway, route tables
- ✅ Security groups
- ✅ IAM roles and policies (defined in Terraform)
- ✅ IAM instance profiles
- ✅ ECR repositories (frontend, backend) **if defined in ecr_repositories.tf**
- ✅ Any other resources defined in .tf files

**Wait Time:** 5-10 minutes

**Alternative: Skip confirmation prompt (use with caution):**
```bash
terraform destroy -var-file=variables.tfvars -auto-approve
```

**Verify Terraform destruction:**
```bash
# Check Terraform state is empty
terraform state list
# Should return empty (no resources in state)

# Verify specific resources are deleted
# Check EC2 instances
aws ec2 describe-instances --region us-east-1 --filters "Name=tag:Name,Values=jenkins-server" --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
# Should show 'terminated' state or no results

# Check VPC (if created by Terraform)
aws ec2 describe-vpcs --region us-east-1 --filters "Name=tag:Name,Values=jenkins-vpc" --query 'Vpcs[*].[VpcId,State]' --output table
# Should return empty list

# Check EIP (if managed by Terraform)
aws ec2 describe-addresses --region us-east-1 --query 'Addresses[*].[AllocationId,PublicIp,InstanceId]' --output table
# Should NOT show Jenkins EIP

# Check ECR repositories (if managed by Terraform)
aws ecr describe-repositories --region us-east-1
# Should NOT show frontend/backend repos
```

**Troubleshooting Terraform destroy failures:**

**Issue 1: Dependency errors (VPC, Security Groups, ENIs)**
```bash
# Check for remaining ENIs (Elastic Network Interfaces)
aws ec2 describe-network-interfaces --region us-east-1 --filters "Name=vpc-id,Values=<VPC-ID>" --query 'NetworkInterfaces[*].[NetworkInterfaceId,Status,Description]' --output table

# If ENIs found, delete them manually
aws ec2 delete-network-interface --network-interface-id <eni-id> --region us-east-1

# Retry Terraform destroy
terraform destroy -var-file=variables.tfvars
```

**Issue 2: EIP still associated**
```bash
# Disassociate EIP first
aws ec2 disassociate-address --association-id <association-id> --region us-east-1

# Then retry Terraform destroy
terraform destroy -var-file=variables.tfvars
```

**Issue 3: Security group in use**
```bash
# Find what's using the security group
aws ec2 describe-network-interfaces --region us-east-1 --filters "Name=group-id,Values=<sg-id>" --query 'NetworkInterfaces[*].[NetworkInterfaceId,Description]'

# Delete those resources, then retry Terraform destroy
```

**Issue 4: ECR repositories not empty**
```bash
# If ECR deletion fails, force delete all images first
aws ecr batch-delete-image \
    --repository-name frontend \
    --region us-east-1 \
    --image-ids "$(aws ecr list-images --repository-name frontend --region us-east-1 --query 'imageIds[*]' --output json)" || true

# Then retry Terraform destroy
terraform destroy -var-file=variables.tfvars
```

**Last resort: Force state removal (use with extreme caution)**
```bash
# Only if Terraform destroy fails repeatedly and resources are already deleted manually
terraform state rm <resource_name>  # Remove specific resource from state
# OR
rm -rf terraform.tfstate terraform.tfstate.backup  # Nuclear option - use only if all resources confirmed deleted
```

---

#### **Step 5: Manual Cleanup Verification**

Verify all resources have been deleted and check for any orphaned resources.

```bash
# Check for remaining EKS clusters
aws eks list-clusters --region us-east-1
# Should return empty list

# Check for remaining EC2 instances
aws ec2 describe-instances --region us-east-1 --filters "Name=instance-state-name,Values=running,pending,stopping,stopped" --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' --output table
# Should NOT show jenkins-server or any EKS worker nodes

# Check for Application Load Balancers
aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[*].[LoadBalancerName,DNSName,State.Code]' --output table
# Should NOT show k8s-sharedalb-* ALBs

# Check for EBS volumes
aws ec2 describe-volumes --region us-east-1 --filters "Name=status,Values=available,in-use" --query 'Volumes[*].[VolumeId,Size,State,Tags[?Key==`Name`].Value|[0]]' --output table
# Should NOT show jenkins-server, mongodb-pv, prometheus-pv, or grafana-pv volumes

# Check for Elastic IPs
aws ec2 describe-addresses --region us-east-1 --query 'Addresses[*].[AllocationId,PublicIp,AssociationId]' --output table
# Should NOT show Jenkins EIP (eipalloc-0db2aba87e747816b)

# Check for CloudFormation stacks
aws cloudformation list-stacks --region us-east-1 --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --query 'StackSummaries[*].[StackName,StackStatus]' --output table
# Should NOT show active eksctl-* or Jenkins-related stacks

# Check for IAM roles created by project
aws iam list-roles --query 'Roles[?contains(RoleName, `eksctl`) || contains(RoleName, `jenkins`) || contains(RoleName, `argocd`)].RoleName' --output table
# Should return empty list

# Check for VPCs
aws ec2 describe-vpcs --region us-east-1 --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],CidrBlock]' --output table
# Should only show default VPC (if any)
```

---

#### **Step 6: Delete Orphaned Resources (If Any)**

If verification shows any remaining resources, manually delete them.

**Delete orphaned EBS volumes:**
```bash
# List available volumes
aws ec2 describe-volumes --region us-east-1 --filters "Name=status,Values=available" --query 'Volumes[*].VolumeId' --output text

# Delete each volume
aws ec2 delete-volume --volume-id <volume-id> --region us-east-1
```

**Delete orphaned security groups:**
```bash
# List security groups (excluding default)
aws ec2 describe-security-groups --region us-east-1 --query 'SecurityGroups[?GroupName!=`default`].[GroupId,GroupName,VpcId]' --output table

# Delete security group
aws ec2 delete-security-group --group-id <sg-id> --region us-east-1
```

**Delete orphaned CloudWatch log groups:**
```bash
# List log groups related to project
aws logs describe-log-groups --region us-east-1 --query 'logGroups[?contains(logGroupName, `three-tier`) || contains(logGroupName, `jenkins`) || contains(logGroupName, `eks`)].logGroupName' --output table

# Delete log group
aws logs delete-log-group --log-group-name <log-group-name> --region us-east-1
```

**Delete orphaned IAM roles/policies:**
```bash
# List roles
aws iam list-roles --query 'Roles[?contains(RoleName, `eksctl`) || contains(RoleName, `jenkins`)].RoleName' --output table

# Delete role (detach policies first)
aws iam list-attached-role-policies --role-name <role-name>
aws iam detach-role-policy --role-name <role-name> --policy-arn <policy-arn>
aws iam delete-role --role-name <role-name>
```

---

#### **Step 7: Cost Verification**

After cleanup, verify no charges are accumulating.

```bash
# Check for running instances
aws ec2 describe-instances --region us-east-1 --filters "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]' --output table

# Check AWS Cost Explorer (via Console)
# Navigate to: AWS Console → Billing → Cost Explorer
# Filter by: Last 7 days, Group by Service
# Verify: No charges for EC2, EKS, ALB, EBS, ECR
```

**Expected costs after cleanup:**
- ✅ EC2: $0/day (no running instances)
- ✅ EKS: $0/day (cluster deleted)
- ✅ ALB: $0/day (load balancers deleted)
- ✅ EBS: $0/day (volumes deleted)
- ✅ ECR: $0/day (repositories deleted, no storage)

**Possible remaining charges:**
- ⚠️ S3 storage (Terraform state, logs) - minimal ($0.01-0.10/month)
- ⚠️ CloudWatch logs retention - minimal ($0.01-0.05/month)
- ⚠️ NAT Gateway (if not deleted) - **EXPENSIVE** ($30-45/month)
- ⚠️ Route53 Hosted Zone (if created) - $0.50/month per zone

---

### Summary Checklist

Use this checklist to ensure complete cleanup:

#### Kubernetes Resources (kubectl/Helm)
- [ ] **Step 1:** Deleted all ArgoCD applications (backend, frontend, database, ingress)
- [ ] **Step 1:** Deleted Ingress resources (mainlb, monitoring-ingress)
- [ ] **Step 1:** Uninstalled Prometheus and Grafana Helm charts
- [ ] **Step 1:** Deleted namespaces (argocd, three-tier, monitoring)
- [ ] **Step 1:** Verified ALB deletion (no k8s-sharedalb-* ALBs exist)

#### EKS Cluster (eksctl)
- [ ] **Step 2:** Ran `eksctl delete cluster --name three-tier-eks-cluster`
- [ ] **Step 2:** Verified cluster deletion (no three-tier-eks-cluster in `aws eks list-clusters`)
- [ ] **Step 2:** Verified CloudFormation stacks deleted (eksctl-* stacks show DELETE_COMPLETE)

#### Terraform Infrastructure (PRIMARY METHOD)
- [ ] **Step 4:** Ran `terraform destroy -var-file=variables.tfvars` in Jenkins-Server-TF/
- [ ] **Step 4:** Confirmed destruction by typing 'yes' when prompted
- [ ] **Step 4:** Verified Jenkins EC2 instance terminated
- [ ] **Step 4:** Verified VPC, subnets, IGW, route tables deleted
- [ ] **Step 4:** Verified Security Groups deleted
- [ ] **Step 4:** Verified EIP released
- [ ] **Step 4:** Verified IAM roles/policies deleted (Terraform-managed ones)
- [ ] **Step 4:** Verified ECR repositories deleted (if managed by Terraform)
- [ ] **Step 4:** Verified `terraform state list` returns empty

#### Final Verification
- [ ] **Step 5:** No orphaned EC2 instances running
- [ ] **Step 5:** No orphaned EBS volumes (available state)
- [ ] **Step 5:** No orphaned Application Load Balancers
- [ ] **Step 5:** No orphaned Elastic IPs
- [ ] **Step 5:** No eksctl-* or Jenkins-related CloudFormation stacks active
- [ ] **Step 5:** No project-related IAM roles remaining
- [ ] **Step 7:** AWS Cost Explorer shows $0/day for EC2, EKS, ALB, EBS, ECR
- [ ] **DNS:** Updated/deleted DNS records on Hostinger (todo.tarang.cloud, monitoring.tarang.cloud)

---

### Quick Teardown Commands (Copy-Paste)

For experienced users, here's the complete teardown in one script:

```bash
#!/bin/bash
# Complete Infrastructure Teardown Script
# Run from: End-to-End-Kubernetes-Three-Tier-DevSecOps-Project/

set -e  # Exit on error

echo "=== STEP 1: Deleting Kubernetes Resources ==="
aws eks update-kubeconfig --name three-tier-eks-cluster --region us-east-1
kubectl delete application -n argocd backend frontend database ingress --wait=true || true
kubectl delete ingress -n three-tier mainlb --wait=true || true
kubectl delete ingress -n monitoring monitoring-ingress --wait=true || true
helm uninstall prometheus -n monitoring || true
helm uninstall grafana -n monitoring || true
kubectl delete namespace argocd --wait=true || true
kubectl delete namespace three-tier --wait=true || true
kubectl delete namespace monitoring --wait=true || true

echo "Waiting 5 minutes for ALB deletion..."
sleep 300

echo "=== STEP 2: Deleting EKS Cluster ==="
eksctl delete cluster --name three-tier-eks-cluster --region us-east-1 --wait

echo "=== STEP 3: Destroying Terraform Infrastructure ==="
cd Jenkins-Server-TF
terraform destroy -var-file=variables.tfvars -auto-approve

echo "=== STEP 4: Final Verification ==="
aws eks list-clusters --region us-east-1
aws ec2 describe-instances --region us-east-1 --filters "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' --output table
aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[*].[LoadBalancerName,State.Code]' --output table
aws ec2 describe-volumes --region us-east-1 --filters "Name=status,Values=available" --query 'Volumes[*].[VolumeId,Size,State]' --output table

echo "=== Teardown Complete! ==="
echo "Please verify AWS Cost Explorer in 2-3 days to confirm no ongoing charges."
echo "Remember to update DNS records on Hostinger if needed."
```

**Usage:**
```bash
# Save as teardown.sh
chmod +x teardown.sh
./teardown.sh
```

**⚠️ Warning:** This script destroys ALL infrastructure. Use with caution!

---

### Time Estimates

| Step | Action | Command Time | AWS Wait Time |
|------|--------|--------------|---------------|
| **Step 1** | Delete K8s resources | 2 minutes | 5-10 minutes (ALB deletion) |
| **Step 2** | Delete EKS cluster | 2 minutes | 15-20 minutes |
| **Step 3** | (Optional) Manual ECR cleanup | 3 minutes | 1-2 minutes |
| **Step 4** | **Terraform destroy** ⭐ | 2 minutes | 5-10 minutes |
| **Step 5** | Manual verification | 5-10 minutes | - |
| **Step 6** | Delete orphaned resources (if any) | 5 minutes | 2-5 minutes |
| **Step 7** | Cost verification | 5 minutes | - |
| **Total Time** | **~25-30 minutes** | **~30-50 minutes** |

**Complete teardown time:** 1-1.5 hours (including all wait times)

**Fast track (using automation script):** ~30-40 minutes total

---

### Important Notes

**✅ Recommended Approach:**
- **Use Terraform destroy** as the primary destruction method for Jenkins infrastructure
- Let Terraform handle VPC, EC2, ECR, IAM, Security Groups automatically
- Only manually intervene if Terraform destroy fails

**📋 Destruction Order (CRITICAL):**
1. **First:** Delete K8s resources (applications, services, ingress) → removes ALB
2. **Second:** Delete EKS cluster with eksctl → removes cluster and node groups
3. **Third:** Run `terraform destroy` → removes all Terraform-managed infrastructure
4. **Fourth:** Verify and clean up any orphaned resources

**⚠️ Common Pitfalls:**
- **Don't skip Step 1:** K8s-created ALBs must be deleted before EKS cluster deletion
- **Don't run Terraform destroy first:** It may fail due to VPC dependencies from EKS
- **Don't manually delete resources managed by Terraform:** Let Terraform handle them
- **Do wait for deletions to complete:** AWS takes time to fully remove resources

**💡 Pro Tips:**
- Run `terraform state list` before destroy to see exactly what will be deleted
- Use `terraform destroy --target=<resource>` to selectively destroy specific resources
- Keep Terraform state file (`terraform.tfstate`) until all resources are confirmed deleted
- Check AWS Cost Explorer 2-3 days after teardown to confirm zero charges

---

## 📚 Additional Resources

- **Complete Technical Documentation:** [DOCUMENTATION.md](./DOCUMENTATION.md)
- **Future Enhancements:** [FUTURE-ENHANCEMENTS.md](./FUTURE-ENHANCEMENTS.md)
- **Cost Management:** [AWS-COST-MANAGEMENT.md](./AWS-COST-MANAGEMENT.md)
- **Post-Shutdown Recovery:** [POST-SHUTDOWN-RECOVERY-CHECKLIST.md](./POST-SHUTDOWN-RECOVERY-CHECKLIST.md)
- **Architecture Diagrams:** [assets/](../assets/)

---

## 🎯 Success Metrics

After completing this guide, you should have:

- ✅ Fully automated CI/CD pipeline with security scanning
- ✅ GitOps-based deployment with ArgoCD
- ✅ Production-ready three-tier application on EKS
- ✅ Comprehensive monitoring with Prometheus and Grafana
- ✅ Security scanning with SonarQube and Trivy
- ✅ Infrastructure as Code with Terraform
- ✅ Zero-downtime deployments with automatic image updates

**Estimated Total Cost:** ~$100-150/month (see [AWS-COST-MANAGEMENT.md](./AWS-COST-MANAGEMENT.md) for breakdown)

---

## 📝 Notes

- All timestamps and tags use `YYYYMMDD-BUILD` format (e.g., `20241126-001`)
- ArgoCD Image Updater uses semantic version regex: `^[0-9-]+$` to match these tags
- Jenkins does **NOT** update Kubernetes manifests - ArgoCD handles all deployments
- Keep your AWS resources shut down when not in use to minimize costs

---

**Last Updated:** November 26, 2024  
**Project:** Three-Tier DevSecOps Kubernetes Project  
**Maintainer:** Udit Mishra
