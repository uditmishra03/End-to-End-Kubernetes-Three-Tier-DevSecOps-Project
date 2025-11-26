# 🚀 Getting Started - Complete Deployment Guide

## Overview

This guide provides a **step-by-step deployment order** for setting up the entire Three-Tier DevSecOps Kubernetes project from scratch. Follow these steps sequentially to deploy the complete infrastructure and application.

**Total Setup Time:** ~4-6 hours (depending on AWS resource provisioning)

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
1. **Cleanup Workspace**
2. **Checkout Code**
3. **SonarQube Analysis** (Code quality)
4. **Quality Gate** (Pass/Fail check)
5. **Install Dependencies** (npm install)
6. **Trivy FS Scan** (File system security scan)
7. **Docker Build & Tag** (Build image with YYYYMMDD-BUILD format)
8. **Trivy Image Scan** (Container security scan)
9. **Docker Push to ECR** (Push to AWS ECR)

**Time:** ~15-20 minutes per pipeline

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

# Install Prometheus (installs to default namespace)
helm install stable prometheus-community/kube-prometheus-stack -n default
```

#### 10.2 Access Prometheus

**Via LoadBalancer:**
```bash
# Prometheus is already exposed via LoadBalancer
kubectl get svc stable-kube-prometheus-sta-prometheus -n default

# Access URL:
# http://aba486402dcc7489db934c692c09b53f-468856416.us-east-1.elb.amazonaws.com:9090
```

**Or via Port Forward:**
```bash
kubectl port-forward -n default svc/prometheus-operated 9090:9090
# Access at: http://localhost:9090
```

#### 10.3 Access Grafana

**Via LoadBalancer (Recommended):**
```bash
# Grafana is already exposed via LoadBalancer
kubectl get svc stable-grafana -n default

# Access URL:
# http://a2c6af4284b0a492ca5361c0f803d6d2-1545715117.us-east-1.elb.amazonaws.com
```

**Get Admin Password:**
```bash
kubectl get secret -n default stable-grafana -o jsonpath="{.data.admin-password}" | base64 -d
echo

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

#### 10.5 Import Dashboards

In Grafana UI:
1. **Click + → Import**
2. **Import these dashboard IDs:**
   - `15760` - Kubernetes / Views / Global
   - `15761` - Kubernetes / Views / Namespaces
   - `15762` - Kubernetes / Views / Pods
   - `6417` - Kubernetes Cluster Monitoring
   - `13770` - Kubernetes Cluster (Prometheus)
3. **Select Prometheus data source** for each
4. **Click Import**

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
