# End-to-End Kubernetes Three-Tier DevSecOps Project

## Complete Implementation Guide

**Version:** 1.0  
**Last Updated:** November 15, 2025  
**Project Owner:** uditmishra03  
**Repository:** [End-to-End-Kubernetes-Three-Tier-DevSecOps-Project](https://github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project)

---

## 📑 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Overview](#2-architecture-overview)
3. [Technology Stack](#3-technology-stack)
4. [Prerequisites and Initial Setup](#4-prerequisites-and-initial-setup)
5. [Jenkins Infrastructure Setup](#5-jenkins-infrastructure-setup)
6. [Jenkins Configuration and Integration](#6-jenkins-configuration-and-integration)
7. [Amazon EKS Cluster Setup](#7-amazon-eks-cluster-setup)
8. [Application Architecture](#8-application-architecture)
9. [CI/CD Pipeline Implementation](#9-cicd-pipeline-implementation)
10. [Kubernetes Deployment](#10-kubernetes-deployment)
11. [ArgoCD and GitOps Setup](#11-argocd-and-gitops-setup)
12. [Monitoring with Prometheus](#12-monitoring-with-prometheus)
13. [Grafana Setup and Enhancements](#13-grafana-setup-and-enhancements)
14. [Jenkins Enhancements (Planned)](#14-jenkins-enhancements-planned)
15. [Troubleshooting and Maintenance](#15-troubleshooting-and-maintenance)
16. [References and Best Practices](#16-references-and-best-practices)

---

## 1. Project Overview

### 1.1 Introduction

End-to-end **DevSecOps** implementation for a **Three-Tier Web Application** on **AWS EKS**, demonstrating modern practices: IaC, CI/CD, security scanning, GitOps, and monitoring.

### 1.2 Key Features

**Current Implementation:**
- ✅ Infrastructure as Code (Terraform)
- ✅ CI/CD with Jenkins (SonarQube + Trivy security scanning)
- ✅ AWS EKS with auto-scaling
- ✅ Private ECR repositories
- ✅ GitOps deployment (ArgoCD)
- ✅ Monitoring (Prometheus + Grafana)
- ✅ AWS ALB Ingress with persistent storage

**Planned Enhancements:**
- 🚀 Advanced Grafana dashboards with alerting
- 🚀 Pipeline optimization (parallel execution, automated rollbacks)

---

## 2. Architecture Overview

### 2.1 System Architecture

**[PLACEHOLDER: High-Level Architecture Diagram]**
*Complete DevSecOps workflow: Developer → GitHub → Jenkins → ECR → EKS → Monitoring*

### 2.2 Deployment Workflow

```
Developer → GitHub → Jenkins (Build/Scan/Push) → ECR → ArgoCD → EKS → Prometheus/Grafana
```

**Pipeline Flow:**
1. Code commit triggers Jenkins webhook
2. SonarQube analyzes code quality
3. Trivy scans for vulnerabilities
4. Docker builds and pushes to ECR
5. Jenkins updates K8s manifests
6. ArgoCD syncs changes to EKS
7. Prometheus/Grafana monitor application

---

## 3. Technology Stack

### Core Technologies

| Category | Technologies |
|----------|-------------|
| **Cloud** | AWS (EKS, ECR, EC2, VPC, ALB) |
| **IaC** | Terraform, AWS CLI, eksctl, Helm |
| **CI/CD** | Jenkins, ArgoCD, SonarQube, Trivy, Docker |
| **Application** | React 17, Node.js/Express 4, MongoDB 4.4 |
| **Monitoring** | Prometheus, Grafana |
| **Container Orchestration** | Kubernetes 1.28+ |

---

## 4. Prerequisites and Initial Setup

### 4.1 AWS Account Setup

**Requirements:**
- Active AWS account with admin access
- Billing alerts configured (recommended)

⚠️ **Resources with Costs:** EC2 (t2.2xlarge), EKS cluster, ECR, ALB, EBS volumes

### 4.2 IAM Configuration

**Create IAM Users:**

1. **terraform-user** - Programmatic access
   - Policies: `AmazonEC2FullAccess`, `AmazonVPCFullAccess`, `IAMFullAccess`

2. **eks-admin** - Programmatic access
   - Policies: `AmazonEKSClusterPolicy`, `AmazonEC2ContainerRegistryFullAccess`

**Configure AWS CLI:**
```bash
aws configure
# Enter: Access Key, Secret Key, Region (us-east-1), Output (json)
aws sts get-caller-identity  # Verify
```

### 4.3 Install Required Tools

**Quick Install (Ubuntu/Linux):**
```bash
# Git
sudo apt update && sudo apt install git -y

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y

# kubectl
curl -LO "https://dl.k8s.io/release/v1.28.4/bin/linux/amd64/kubectl"
sudo chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Verify Installation:**
```bash
aws --version && terraform --version && kubectl version --client && eksctl version && helm version
```

### 4.4 Clone Repository

```bash
git clone https://github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git
cd End-to-End-Kubernetes-Three-Tier-DevSecOps-Project
```

### 4.5 Create SSH Key for EC2

```bash
aws ec2 create-key-pair --key-name jenkins-server-key --query 'KeyMaterial' --output text > jenkins-server-key.pem
chmod 400 jenkins-server-key.pem
```

### 4.6 Prerequisites Checklist

- [ ] AWS CLI configured and verified
- [ ] IAM users created with proper policies
- [ ] All tools installed (terraform, kubectl, eksctl, helm)
- [ ] Repository cloned
- [ ] SSH key pair created

---

## 5. Jenkins Infrastructure Setup

### 5.1 Terraform Configuration Overview

The `Jenkins-Server-TF/` directory contains Infrastructure as Code for automated Jenkins server provisioning.

**Key Components:**
- **VPC & Networking** - Isolated network environment
- **EC2 Instance** - t2.2xlarge Ubuntu 22.04 with 30GB storage
- **Security Groups** - Ports 22, 80, 443, 8080, 9000
- **IAM Role** - EC2 permissions for AWS services
- **Automated Setup** - Tools pre-installed via user-data script

### 5.2 Update Configuration

Edit `Jenkins-Server-TF/variables.tfvars`:
```hcl
vpc-name       = "jenkins-vpc"
igw-name       = "jenkins-igw"
subnet-name    = "jenkins-subnet"
sg-name        = "jenkins-sg"
instance-name  = "jenkins-server"
key-name       = "jenkins-server-key"  # Your SSH key name
iam-role       = "jenkins-role"
```

### 5.3 Deploy Infrastructure

```bash
cd Jenkins-Server-TF

# Initialize Terraform
terraform init

# Review execution plan
terraform plan -var-file=variables.tfvars

# Deploy infrastructure
terraform apply -var-file=variables.tfvars -auto-approve
```

**[PLACEHOLDER: Terraform Apply Output]**

### 5.4 Pre-installed Tools

The `tools-install.sh` script automatically installs:
- ✅ Java 17 (OpenJDK)
- ✅ Jenkins
- ✅ Docker
- ✅ SonarQube (Docker container)
- ✅ AWS CLI
- ✅ kubectl (v1.28.4)
- ✅ eksctl
- ✅ Terraform
- ✅ Trivy
- ✅ Helm

### 5.5 Access Jenkins Server

```bash
# Get EC2 public IP
terraform output

# SSH into server
ssh -i jenkins-server-key.pem ubuntu@<EC2-PUBLIC-IP>

# Check Jenkins status
sudo systemctl status jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Access Jenkins: `http://<EC2-PUBLIC-IP>:8080`

---

## 6. Jenkins Configuration and Integration

### 6.1 Initial Setup

1. **Unlock Jenkins** - Use password from `/var/lib/jenkins/secrets/initialAdminPassword`
2. **Install Suggested Plugins**
3. **Create Admin User**

### 6.2 Install Required Plugins

Navigate to: **Manage Jenkins → Plugins → Available Plugins**

Install:
- Eclipse Temurin Installer
- SonarQube Scanner
- NodeJS
- Docker, Docker Pipeline
- Kubernetes CLI
- Multibranch Scan Webhook Trigger

### 6.3 Configure Tools

**Manage Jenkins → Tools**

**JDK:**
- Name: `jdk`
- Install from adoptium.net
- Version: jdk-17.0.8+7

**Node.js:**
- Name: `nodejs`
- Version: 16.0.0

**SonarQube Scanner:**
- Name: `sonar-scanner`
- Install automatically from Maven Central

### 6.4 SonarQube Integration

**Start SonarQube:**
```bash
# Already running as Docker container on port 9000
docker ps | grep sonar
```

Access: `http://<EC2-IP>:9000` (admin/admin, change password)

**Configure in Jenkins:**
1. **Manage Jenkins → System → SonarQube servers**
   - Name: `sonar-server`
   - URL: `http://<EC2-PRIVATE-IP>:9000`
   - Authentication: Add SonarQube token

2. **Generate SonarQube Token:**
   - SonarQube → My Account → Security → Generate Token
   - Add to Jenkins credentials as "Secret text" (ID: `sonar-token`)

### 6.5 Configure Credentials

**Manage Jenkins → Credentials → Global**

Add following credentials:

| ID | Type | Description |
|----|------|-------------|
| `ACCOUNT_ID` | Secret text | AWS Account ID |
| `ECR_REPO01` | Secret text | `frontend` |
| `ECR_REPO02` | Secret text | `backend` |
| `GITHUB` | Username/Password | GitHub credentials |
| `github` | Secret text | GitHub Personal Access Token |
| `sonar-token` | Secret text | SonarQube token |

**[PLACEHOLDER: Jenkins Credentials Screenshot]**

### 6.6 Create ECR Repositories

```bash
# Frontend repository
aws ecr create-repository --repository-name frontend --region us-east-1

# Backend repository
aws ecr create-repository --repository-name backend --region us-east-1
```

### 6.7 Setup GitHub Webhook

**In GitHub Repository:**
1. Settings → Webhooks → Add webhook
2. Payload URL: `http://<JENKINS-IP>:8080/github-webhook/`
3. Content type: `application/json`
4. Events: `Just the push event`

**[PLACEHOLDER: GitHub Webhook Screenshot]**

### 6.8 Create Jenkins Pipelines

**Create Two Pipeline Jobs:**

1. **Frontend-Pipeline**
   - Type: Pipeline
   - Pipeline script from SCM: Git
   - Repository: Your GitHub repo URL
   - Script Path: `Jenkins-Pipeline-Code/Jenkinsfile-Frontend`

2. **Backend-Pipeline**
   - Type: Pipeline
   - Pipeline script from SCM: Git
   - Repository: Your GitHub repo URL
   - Script Path: `Jenkins-Pipeline-Code/Jenkinsfile-Backend`

---

## 7. Amazon EKS Cluster Setup

### 7.1 Create EKS Cluster

```bash
eksctl create cluster \
  --name three-tier-cluster \
  --region us-east-1 \
  --node-type t2.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3
```

⏱️ **Note:** Cluster creation takes ~15-20 minutes

### 7.2 Verify Cluster

```bash
# Configure kubectl
aws eks update-kubeconfig --name three-tier-cluster --region us-east-1

# Verify connection
kubectl get nodes
kubectl get ns
```

### 7.3 Create Namespace

```bash
kubectl create namespace three-tier
kubectl get ns
```

### 7.4 Install AWS Load Balancer Controller

```bash
# Download IAM policy
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json

# Create IAM service account
eksctl create iamserviceaccount \
  --cluster=three-tier-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::<AWS-ACCOUNT-ID>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Add Helm repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=three-tier-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Verify
kubectl get deployment -n kube-system aws-load-balancer-controller
```

### 7.5 Create ECR Secret

```bash
# Get ECR login token
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=<AWS-ACCOUNT-ID>.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --namespace=three-tier
```

---

## 8. Application Architecture

### 8.1 Three-Tier Architecture Overview

**[PLACEHOLDER: Application Architecture Diagram]**

**Architecture Layers:**

| Layer | Technology | Port | Purpose |
|-------|-----------|------|---------|
| **Frontend** | React.js 17 | 3000 | User interface, Material-UI components |
| **Backend** | Node.js/Express 4 | 3500 | REST API, business logic |
| **Database** | MongoDB 4.4 | 27017 | Data persistence, document storage |

### 8.2 Application Components

#### Frontend (React.js)
```
Application-Code/frontend/
├── src/
│   ├── App.js           # Main component
│   ├── Tasks.js         # Task management logic
│   └── services/
│       └── taskServices.js  # API client
├── Dockerfile
└── package.json
```

**Key Features:**
- Material-UI for responsive design
- Axios for HTTP requests
- Task CRUD operations

**Environment Variable:**
```bash
REACT_APP_BACKEND_URL=http://<ALB-DNS>/api/tasks
```

#### Backend (Node.js/Express)
```
Application-Code/backend/
├── index.js           # Server entry point
├── db.js             # MongoDB connection
├── routes/
│   └── tasks.js      # Task API routes
├── models/
│   └── task.js       # Task schema
├── Dockerfile
└── package.json
```

**API Endpoints:**
- `GET /api/tasks` - Fetch all tasks
- `POST /api/tasks` - Create task
- `PUT /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task
- `GET /healthz` - Liveness probe
- `GET /ready` - Readiness probe
- `GET /started` - Startup probe

**Environment Variables:**
```bash
MONGO_CONN_STR=mongodb://mongodb-svc:27017/todo
MONGO_USERNAME=<from-secret>
MONGO_PASSWORD=<from-secret>
```

#### Database (MongoDB)
- **Image:** mongo:4.4.6
- **Storage:** PersistentVolume (EBS)
- **Authentication:** Kubernetes secrets
- **Configuration:** WiredTiger cache optimization

### 8.3 Communication Flow

```
User → ALB Ingress → Frontend Service (3000)
                 ↓
        Frontend Pod → Backend Service (3500)
                 ↓
            Backend Pod → MongoDB Service (27017)
                 ↓
            MongoDB Pod → PersistentVolume
```

### 8.4 Dockerfiles

**Frontend Dockerfile:**
```dockerfile
FROM node:14
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

**Backend Dockerfile:**
```dockerfile
FROM node:14
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3500
CMD ["node", "index.js"]
```

---

## 9. CI/CD Pipeline Implementation

### 9.1 Pipeline Overview

Two identical pipelines (Frontend & Backend) with the following stages:

```
Clean Workspace → Git Checkout → SonarQube Analysis → Quality Gate → 
Trivy Scan → Docker Build → ECR Push → Trivy Image Scan → Update Deployment
```

### 9.2 Pipeline Stages Explained

**1. Workspace Cleanup**
```groovy
stage('Cleaning Workspace') {
    steps { cleanWs() }
}
```

**2. Code Checkout**
```groovy
stage('Checkout from Git') {
    steps {
        git credentialsId: 'GITHUB', 
            url: 'https://github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git'
    }
}
```

**3. SonarQube Code Analysis**
```groovy
stage('Sonarqube Analysis') {
    steps {
        dir('Application-Code/backend') {  // or frontend
            withSonarQubeEnv('sonar-server') {
                sh '''$SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=three-tier-backend \
                    -Dsonar.projectKey=three-tier-backend'''
            }
        }
    }
}
```

**4. Quality Gate Check**
```groovy
stage('Quality Check') {
    steps {
        script {
            waitForQualityGate abortPipeline: false, 
                               credentialsId: 'sonar-token'
        }
    }
}
```

**5. Trivy Filesystem Scan**
```groovy
stage('Trivy File Scan') {
    steps {
        script {
            catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                sh 'trivy fs . > trivyfs.txt'
            }
        }
    }
}
```

**6. Docker Image Build**
```groovy
stage("Docker Image Build") {
    steps {
        script {
            sh 'docker system prune -f'
            sh 'docker build -t ${AWS_ECR_REPO_NAME} .'
        }
    }
}
```

**7. Push to ECR**
```groovy
stage("ECR Image Pushing") {
    steps {
        script {
            sh 'aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${REPOSITORY_URI}'
            sh 'docker tag ${AWS_ECR_REPO_NAME} ${REPOSITORY_URI}${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}'
            sh 'docker push ${REPOSITORY_URI}${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}'
        }
    }
}
```

**8. Trivy Image Scan**
```groovy
stage("TRIVY Image Scan") {
    steps {
        script {
            catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                sh 'trivy image ${REPOSITORY_URI}${AWS_ECR_REPO_NAME}:${BUILD_NUMBER} > trivyimage.txt'
            }
        }
    }
}
```

**9. Update Kubernetes Manifest (GitOps)**
```groovy
stage('Update Deployment file') {
    steps {
        dir('Kubernetes-Manifests-file/Backend') {
            withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
                sh '''
                    git config user.email "uditmishra.um@gmail.com"
                    git config user.name "uditmishra03"
                    sed -i "s/${AWS_ECR_REPO_NAME}:${imageTag}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}/" deployment.yaml
                    git add deployment.yaml
                    git commit -m "Update deployment Image to version ${BUILD_NUMBER}"
                    git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:master
                '''
            }
        }
    }
}
```

### 9.3 Pipeline Environment Variables

```groovy
environment {
    SCANNER_HOME = tool 'sonar-scanner'
    AWS_ACCOUNT_ID = credentials('ACCOUNT_ID')
    AWS_ECR_REPO_NAME = credentials('ECR_REPO01')  // or ECR_REPO02
    AWS_DEFAULT_REGION = 'us-east-1'
    REPOSITORY_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/"
}
```

### 9.4 Trigger Pipeline

**Manual Trigger:**
- Click "Build Now" in Jenkins

**Automatic Trigger:**
- Push code to GitHub → Webhook triggers pipeline

### 9.5 Pipeline Execution Flow

```
Code Push → GitHub Webhook → Jenkins Pipeline Starts
    ↓
SonarQube Analysis (Quality & Security)
    ↓
Trivy Scan (Vulnerabilities)
    ↓
Docker Build → Tag → Push to ECR
    ↓
Update deployment.yaml with new image tag
    ↓
Push to GitHub → ArgoCD detects change → Deploys to EKS
```

**[PLACEHOLDER: Jenkins Pipeline Execution Screenshot]**

---

## 10. Kubernetes Deployment

### 10.1 Deployment Architecture

```
three-tier namespace
├── Frontend (1 replica)
├── Backend (2 replicas)
├── MongoDB (1 replica + PV)
└── Ingress (ALB)
```

### 10.2 Database Setup

**Create MongoDB Secrets:**
```bash
kubectl create secret generic mongo-sec \
  --from-literal=username=admin \
  --from-literal=password=password123 \
  -n three-tier
```

**Apply Database Manifests:**
```bash
cd Kubernetes-Manifests-file/Database

# Create PersistentVolume
kubectl apply -f pv.yaml

# Create PersistentVolumeClaim
kubectl apply -f pvc.yaml

# Deploy MongoDB
kubectl apply -f deployment.yaml

# Create Service
kubectl apply -f service.yaml

# Verify
kubectl get pods,svc,pvc -n three-tier
```

**Key Configurations:**
- **Storage:** 4Gi EBS volume
- **Authentication:** Root user from secrets
- **Cache:** WiredTiger optimized (0.1GB)
- **Service:** ClusterIP on port 27017

### 10.3 Backend Deployment

**Update deployment.yaml:**
```yaml
image: <AWS-ACCOUNT-ID>.dkr.ecr.us-east-1.amazonaws.com/backend:1
env:
  - name: MONGO_CONN_STR
    value: mongodb://mongodb-svc:27017/todo?directConnection=true
  - name: MONGO_USERNAME
    valueFrom:
      secretKeyRef:
        name: mongo-sec
        key: username
  - name: MONGO_PASSWORD
    valueFrom:
      secretKeyRef:
        name: mongo-sec
        key: password
```

**Deploy Backend:**
```bash
cd Kubernetes-Manifests-file/Backend
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

**Health Checks:**
- **Liveness:** `/healthz` - Port 3500
- **Readiness:** `/ready` - Port 3500
- **Startup:** `/started` - Port 3500

### 10.4 Frontend Deployment

**Update deployment.yaml:**
```yaml
image: <AWS-ACCOUNT-ID>.dkr.ecr.us-east-1.amazonaws.com/frontend:1
env:
  - name: REACT_APP_BACKEND_URL
    value: "http://<ALB-DNS>/api/tasks"
```

**Deploy Frontend:**
```bash
cd Kubernetes-Manifests-file/Frontend
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### 10.5 Ingress Configuration

**Deploy Ingress:**
```bash
kubectl apply -f ingress.yaml
```

**Ingress Routes:**
```yaml
rules:
  - http:
      paths:
      - path: /api          # Backend API
        pathType: Prefix
        backend:
          service:
            name: api
            port: 3500
      - path: /            # Frontend
        pathType: Prefix
        backend:
          service:
            name: frontend
            port: 3000
```

**Get Load Balancer DNS:**
```bash
kubectl get ingress -n three-tier
```

**Update Frontend Deployment:**
```bash
# Edit Frontend deployment with actual ALB DNS
kubectl edit deployment frontend -n three-tier
```

### 10.6 Verification

```bash
# Check all resources
kubectl get all -n three-tier

# Check pods status
kubectl get pods -n three-tier -w

# Check logs
kubectl logs -f deployment/frontend -n three-tier
kubectl logs -f deployment/api -n three-tier
kubectl logs -f deployment/mongodb -n three-tier

# Access application
# Open browser: http://<ALB-DNS>
```

### 10.7 Kubernetes Resources Summary

| Resource | Name | Replicas | Port | Type |
|----------|------|----------|------|------|
| Deployment | frontend | 1 | 3000 | ClusterIP |
| Deployment | api | 2 | 3500 | ClusterIP |
| Deployment | mongodb | 1 | 27017 | ClusterIP |
| Ingress | mainlb | - | 80 | ALB |
| PVC | mongo-volume-claim | - | 4Gi | EBS |

---

## 11. ArgoCD and GitOps Setup

### 11.1 Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Verify installation
kubectl get pods -n argocd -w
```

### 11.2 Access ArgoCD UI

**Get Admin Password:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Port Forward (Local Access):**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Access: `https://localhost:8080` (admin / <password>)

**Or Expose via LoadBalancer:**
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc argocd-server -n argocd
```

### 11.3 Configure ArgoCD Application

**Create Application via UI:**
1. **New App** → **Edit as YAML**
2. Configuration:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: three-tier-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git
    targetRevision: HEAD
    path: Kubernetes-Manifests-file
  destination:
    server: https://kubernetes.default.svc
    namespace: three-tier
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

**Or Using CLI:**
```bash
argocd app create three-tier-app \
  --repo https://github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git \
  --path Kubernetes-Manifests-file \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace three-tier \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

### 11.4 GitOps Workflow

```
Jenkins updates deployment.yaml → Commits to GitHub
    ↓
ArgoCD detects Git changes (every 3 minutes)
    ↓
ArgoCD syncs with EKS cluster
    ↓
New pods deployed with updated image
```

**Verify Sync:**
```bash
argocd app get three-tier-app
argocd app sync three-tier-app  # Manual sync
```

### 11.5 Benefits of GitOps

- ✅ **Single Source of Truth** - Git as declarative state
- ✅ **Automated Deployment** - No manual kubectl commands
- ✅ **Self-Healing** - Auto-corrects drift
- ✅ **Audit Trail** - All changes tracked in Git
- ✅ **Rollback** - Easy revert via Git

---

## 12. Monitoring with Prometheus

### 12.1 Install Prometheus using Helm

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus stack (includes Grafana)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring

# Verify installation
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### 12.2 Access Prometheus

**Port Forward:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
Access: `http://localhost:9090`

**Or Expose via LoadBalancer:**
```bash
kubectl patch svc prometheus-kube-prometheus-prometheus -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
```

### 12.3 Key Metrics Collected

- **Cluster Metrics:** CPU, Memory, Disk usage
- **Node Metrics:** Node health, resource utilization
- **Pod Metrics:** Container resource consumption
- **Application Metrics:** HTTP requests, response times
- **Custom Metrics:** Application-specific metrics

### 12.4 Prometheus Queries (Examples)

```promql
# CPU usage by pod
sum(rate(container_cpu_usage_seconds_total{namespace="three-tier"}[5m])) by (pod)

# Memory usage
container_memory_usage_bytes{namespace="three-tier"}

# HTTP request rate
rate(http_requests_total[5m])

# Pod restart count
kube_pod_container_status_restarts_total{namespace="three-tier"}
```

---

## 13. Grafana Setup and Enhancements

### 13.1 Access Grafana (Current Setup)

**Get Admin Password:**
```bash
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d
```

**Port Forward:**
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```
Access: `http://localhost:3000` (admin / <password>)

**Or Expose via LoadBalancer:**
```bash
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc prometheus-grafana -n monitoring
```

### 13.2 Current Dashboards

Pre-installed dashboards from kube-prometheus-stack:
- **Kubernetes / Compute Resources / Cluster**
- **Kubernetes / Compute Resources / Namespace (Pods)**
- **Kubernetes / Compute Resources / Node (Pods)**
- **Node Exporter / Nodes**

### 13.3 Planned Enhancements 🚀

#### **1. Application-Specific Dashboards**
- **Frontend Dashboard**
  - Page load times
  - API response times
  - Error rates
  - User activity metrics
  
- **Backend Dashboard**
  - API endpoint performance
  - Request/response metrics
  - Database query performance
  - Error tracking

- **Database Dashboard**
  - MongoDB connections
  - Query execution time
  - Document operations (CRUD)
  - Replication lag

#### **2. Custom Metrics Integration**
```javascript
// Example: Instrument Node.js backend
const promClient = require('prom-client');
const register = new promClient.Registry();

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status']
});

register.registerMetric(httpRequestDuration);
```

#### **3. Alerting Rules**
```yaml
# Planned alert rules
alerts:
  - name: HighPodMemory
    expr: container_memory_usage_bytes{namespace="three-tier"} > 500000000
    for: 5m
    severity: warning
    
  - name: PodRestarting
    expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
    severity: critical
    
  - name: HighAPILatency
    expr: http_request_duration_seconds{quantile="0.99"} > 2
    for: 5m
    severity: warning
```

#### **4. Notification Channels**
- **Slack Integration** - Real-time alerts
- **Email Notifications** - Critical alerts
- **PagerDuty** - On-call escalations
- **Webhook** - Custom integrations

#### **5. Advanced Visualizations**
- **SLO/SLI Dashboards** - Service level objectives
- **Business Metrics** - User engagement, task completion
- **Cost Monitoring** - AWS resource costs
- **Capacity Planning** - Resource forecasting

#### **6. Dashboard Organization**
```
📊 Grafana Folders (Planned)
├── Infrastructure
│   ├── Cluster Overview
│   ├── Node Metrics
│   └── Namespace Resources
├── Applications
│   ├── Frontend Performance
│   ├── Backend APIs
│   └── Database Health
├── Business Metrics
│   ├── User Activity
│   └── Task Analytics
└── Alerts & SLOs
```

### 13.4 Implementation Timeline

| Phase | Features | Status |
|-------|----------|--------|
| **Phase 1** | Basic dashboards (Current) | ✅ Complete |
| **Phase 2** | Custom application metrics | 🚀 Planned Q1 2026 |
| **Phase 3** | Advanced alerting | 🚀 Planned Q2 2026 |
| **Phase 4** | Business intelligence dashboards | 🚀 Planned Q2 2026 |

---

## 14. Jenkins Enhancements (Planned)

*This section will be populated in Step 12*

---

## 15. Troubleshooting and Maintenance

*This section will be populated in Step 13*

---

## 16. References and Best Practices

*This section will be populated in Step 14*

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**📝 Note:** This is a living document and will be updated as the project evolves. Screenshots and diagrams can be added manually to the placeholder sections.

**🚀 Happy DevOps Journey!**
