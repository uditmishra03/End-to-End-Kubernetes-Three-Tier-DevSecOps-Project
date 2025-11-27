# End-to-End Kubernetes Three-Tier DevSecOps Project

## Complete Implementation Guide

**Version:** 1.0  
**Last Updated:** November 26, 2025  
**Project Owner:** uditmishra03  
**Repository:** [End-to-End-Kubernetes-Three-Tier-DevSecOps-Project](https://github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project)

---

## 🚀 Quick Start

**New to this project?** Start with the **[Getting Started Guide](./GETTING-STARTED.md)** for step-by-step deployment instructions from scratch to production.

The Getting Started guide provides:
- ✅ Sequential deployment order (Steps 1-11)
- ✅ Time estimates for each phase
- ✅ Verification checkpoints
- ✅ Common troubleshooting tips
- ✅ Complete workflow overview

**This document** provides detailed technical documentation for each component. Use it as a reference after completing the Getting Started guide.

---

## 🏗️ Repository Architecture

This project follows a **microservices architecture** with separate repositories for each service:

### Infrastructure Repository (This Repository)
**[End-to-End-Kubernetes-Three-Tier-DevSecOps-Project](https://github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project)**
- AWS Infrastructure provisioning (Terraform)
- Jenkins CI/CD server setup
- EKS cluster configuration
- Kubernetes manifests for shared infrastructure:
  - Database (MongoDB): deployment, service, PV, PVC, secrets
  - Ingress: AWS ALB configuration
- ArgoCD GitOps configurations
- Monitoring setup (Prometheus, Grafana)
- Automation scripts

### Frontend Microservice
**[three-tier-fe](https://github.com/uditmishra03/three-tier-fe)**
- ReactJS application with modern UI
- Nginx web server configuration
- Kubernetes manifests (deployment.yaml, service.yaml, kustomization.yaml)
- Independent Jenkins pipeline
- Dedicated ECR repository: `frontend`
- Date-based image tagging (YYYYMMDD-BUILD)

### Backend Microservice
**[three-tier-be](https://github.com/uditmishra03/three-tier-be)**
- NodeJS/Express REST API
- MongoDB integration
- Kubernetes manifests (deployment.yaml, service.yaml, kustomization.yaml)
- Independent Jenkins pipeline
- Dedicated ECR repository: `backend`
- Date-based image tagging (YYYYMMDD-BUILD)

### Why Microservices?
- ✅ **Independent Deployments:** Frontend and backend deploy separately
- ✅ **Isolated CI/CD:** Code changes trigger only the affected service pipeline
- ✅ **Better Scalability:** Each service scales independently
- ✅ **Improved Developer Experience:** Teams work in isolation without conflicts
- ✅ **Clear Separation of Concerns:** Infrastructure, frontend, and backend are decoupled

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

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    DEVELOPER                                        │
│                                        │                                            │
│                                    Git Push                                         │
└────────────────────────────────────────┼────────────────────────────────────────────┘
                                         │
                 ┌───────────────────────┼───────────────────────┐
                 │                       │                       │
                 ▼                       ▼                       ▼
┌────────────────────────┐  ┌────────────────────────┐  ┌────────────────────────┐
│   GitHub Repository    │  │   GitHub Repository    │  │   GitHub Repository    │
│   (Infrastructure)     │  │   (three-tier-fe)      │  │   (three-tier-be)      │
│  ┌──────────────────┐  │  │  ┌──────────────────┐  │  │  ┌──────────────────┐  │
│  │ K8s Manifests:   │  │  │  │ React Frontend   │  │  │  │ Node.js Backend  │  │
│  │ - Database       │  │  │  │ Nginx Config     │  │  │  │ Express API      │  │
│  │ - Ingress        │  │  │  │ K8s Manifests    │  │  │  │ K8s Manifests    │  │
│  │ ArgoCD Configs   │  │  │  │ Jenkinsfile      │  │  │  │ Jenkinsfile      │  │
│  │ Terraform IaC    │  │  │  │ Dockerfile       │  │  │  │ Dockerfile       │  │
│  └──────────────────┘  │  │  └──────────────────┘  │  │  └──────────────────┘  │
└───────────┬────────────┘  └───────────┬────────────┘  └───────────┬────────────┘
            │                           │                           │
         Webhook                     Webhook                     Webhook
            │                           │                           │
            └───────────────────────────┼───────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           JENKINS CI/CD SERVER (EC2)                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                      │
│  │  Frontend MBP   │  │  Backend MBP    │  │  Infrastructure │                      │
│  │  - SonarQube    │  │  - SonarQube    │  │  - Terraform    │                      │
│  │  - Trivy Scan   │  │  - Trivy Scan   │  │  - Scripts      │                      │
│  │  - Docker Build │  │  - Docker Build │  │  - Monitoring   │                      │
│  │  - ECR Push     │  │  - ECR Push     │  │                 │                      │
│  └────────┬────────┘  └──────────┬──────┘  └─────────────────┘                      │
└───────────┼──────────────────────┼──────────────────────────────────────────────────┘
            │                      │
            │ Push Image           │ Push Image
            │ (YYYYMMDD-BUILD)     │ (YYYYMMDD-BUILD)
            │                      │
            ▼                      ▼
┌───────────────────────┐    ┌───────────────────────┐
│   AWS ECR Registry    │    │   AWS ECR Registry    │
│   Frontend Repository │    │   Backend Repository  │
│   - Tagged Images     │    │   - Tagged Images     │
│   - Lifecycle Policy  │    │   - Lifecycle Policy  │
│   (Delete untagged    │    │   (Delete untagged    │
│    images > 5 days)   │    │    images > 5 days)   │
└───────────┬───────────┘    └───────────┬───────────┘
            │                            │
            │  ArgoCD Image Updater      │
            │  Monitors ECR Repositories │
            │  for New Tags              │
            └────────────┬───────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────────────────────────────┐
│                                  ARGOCD (GitOps)                                   │
│  ┌─────────────────────────────┐         ┌─────────────────────────────┐           │
│  │  Frontend App               │         │  Backend App                │           │
│  │  - Auto-sync: true          │         │  - Auto-sync: true          │           │
│  │  - Image Updater            │         │  - Image Updater            │           │
│  │  - Tag regex: ^[0-9-]+$     │         │  - Tag regex: ^[0-9-]+$     │           │
│  │  - Direct cluster updates   │         │  - Direct cluster updates   │           │
│  └─────────────┬───────────────┘         └───────────────┬─────────────┘           │
└────────────────┼─────────────────────────────────────────┼─────────────────────────┘
                 │                                         │
                 │ Deploy                                  │ Deploy
                 │                                         │
                 ▼                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                            AWS EKS CLUSTER (Kubernetes)                             │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │                           Namespace: three-tier                              │   │
│  │  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐        │   │
│  │  │ Frontend Pod(s)  │    │ Backend Pod(s)   │    │ MongoDB Pod(s)   │        │   │
│  │  │ - React App      │    │ - Node.js API    │    │ - Database       │        │   │
│  │  │ - Nginx          │◄───┤ - Express        │◄───┤ - Persistent Vol │        │   │
│  │  │ - Port: 3000     │    │ - Port: 3500     │    │ - Port: 27017    │        │   │
│  │  └────────┬─────────┘    └────────┬─────────┘    └──────────────────┘        │   │
│  │           │                       │                                          │   │
│  │  ┌────────▼───────────────────────▼───────┐                                  │   │
│  │  │        Service Mesh / Services         │                                  │   │
│  │  │  - frontend-svc (ClusterIP)            │                                  │   │
│  │  │  - backend-svc (ClusterIP)             │                                  │   │
│  │  │  - mongodb-svc (ClusterIP)             │                                  │   │
│  │  └────────┬───────────────────────────────┘                                  │   │
│  └───────────┼──────────────────────────────────────────────────────────────────┘   │
│              │                                                                      │
│  ┌───────────▼──────────────────────────────────────────────────────────────────┐   │
│  │                     AWS Load Balancer Controller                             │   │
│  │  ┌──────────────┐                                                            │   │
│  │  │   Ingress    │                                                            │   │
│  │  │  - ALB       │                                                            │   │
│  │  │  - Path-based│                                                            │   │
│  │  └──────┬───────┘                                                            │   │
│  └─────────┼────────────────────────────────────────────────────────────────────┘   │
└────────────┼────────────────────────────────────────────────────────────────────────┘
             │
             │ Internet Traffic
             ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          AWS APPLICATION LOAD BALANCER                              │
│  http://<alb-dns>       →  Frontend (React UI)                                      │
│  http://<alb-dns>/api   →  Backend (Node.js API)                                    │
└─────────────────────────────────────────────────────────────────────────────────────┘
              │
              │ HTTP/HTTPS
              ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                  END USERS                                          │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                     MONITORING & OBSERVABILITY (Namespace: default)                 │
│  ┌──────────────────────┐              ┌──────────────────────┐                     │
│  │   Prometheus         │              │   Grafana            │                     │
│  │   - Metrics Collection──────────────►  - Dashboards        │                     │
│  │   - Service Discovery│              │  - Visualizations    │                     │
│  │   - Alert Rules      │              │  - Alerting          │                     │
│  └──────────────────────┘              └──────────────────────┘                     │
│             ▲                                                                       │
│             │ Scrape Metrics                                                        │
│             └─────────────── From All Pods & Services                               │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**Key Architecture Highlights:**

1. **Microservices Separation:**
   - 3 independent Git repositories (Infrastructure, Frontend, Backend)
   - Separate CI/CD pipelines for each service
   - Independent deployment cycles

2. **CI/CD Pipeline:**
   - Webhook-triggered Jenkins Multibranch Pipelines
   - Security scanning (SonarQube + Trivy)
   - Date-based image tagging (YYYYMMDD-BUILD)
   - Automated image builds and ECR pushes

3. **GitOps Deployment:**
   - ArgoCD auto-sync enabled
   - ArgoCD Image Updater monitors ECR for new tags
   - Automatic image updates and deployments to EKS
   - No manual manifest updates required

4. **Container Registry:**
   - Dedicated ECR repositories per service
   - Lifecycle policies for automated cleanup
   - Only tagged images preserved

5. **Kubernetes Cluster:**
   - AWS EKS with auto-scaling node groups
   - Namespace isolation (three-tier, monitoring, argocd)
   - ALB Ingress for external access

6. **Monitoring Stack:**
   - Prometheus for metrics collection
   - Grafana for visualization and alerting
   - Service discovery for auto-monitoring

### 2.2 Deployment Workflow

```
Developer → GitHub → Jenkins (Build/Scan/Push) → ECR → ArgoCD → EKS → Prometheus/Grafana
```

**Pipeline Flow:**
1. Code commit triggers Jenkins webhook
2. SonarQube analyzes code quality
3. Trivy scans for vulnerabilities
4. Docker builds and pushes to ECR with semantic version tag
5. ArgoCD Image Updater detects new image in ECR
6. ArgoCD automatically updates and syncs to EKS
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

### 8.1 Microservices Architecture Overview

This project follows a **microservices architecture** with three separate repositories and is accessible via **HTTPS** using a custom domain with AWS Certificate Manager.

#### HTTPS Request Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              END USER                                    │
│                       (Browser / Mobile Device)                          │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 │ HTTPS Request (Port 443)
                                 │ https://todo.tarang.cloud
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           DNS RESOLUTION                                 │
│                         (Hostinger DNS / Route53)                        │
│                                                                          │
│  CNAME: todo.tarang.cloud → k8s-threetie-mainlb-XXX.elb.amazonaws.com  │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 │ Resolved ALB DNS
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     AWS APPLICATION LOAD BALANCER                        │
│                         (Internet-Facing ALB)                            │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  SSL/TLS Termination                                            │   │
│  │  Certificate: *.tarang.cloud (ACM)                              │   │
│  │  ARN: arn:aws:acm:us-east-1:296062548155:certificate/...       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  Listeners:                                                              │
│  ├─ Port 80 (HTTP)  → Redirect to HTTPS (Port 443)                      │
│  └─ Port 443 (HTTPS) → Forward to Target Groups                         │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 │ HTTP (within VPC)
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    AWS ALB INGRESS CONTROLLER                            │
│                         (Kubernetes Ingress)                             │
│                                                                          │
│  Host-Based Routing: todo.tarang.cloud                                  │
│  Path-Based Routing:                                                    │
│    ├─ /api/*      → Backend Service (api)                               │
│    ├─ /healthz    → Backend Health Check                                │
│    ├─ /ready      → Backend Readiness                                   │
│    ├─ /started    → Backend Startup                                     │
│    └─ /*          → Frontend Service                                    │
└────────────────┬──────────────────────┬─────────────────────────────────┘
                 │                      │
     ┌───────────┴───────┐   ┌──────────┴──────────┐
     │                   │   │                     │
     ▼                   │   ▼                     │
┌─────────────────┐      │  ┌─────────────────┐   │
│  Frontend       │      │  │  Backend (API)  │   │
│  Service        │      │  │  Service        │   │
│  (ClusterIP)    │      │  │  (ClusterIP)    │   │
│  Port: 80       │      │  │  Port: 3500     │   │
└────────┬────────┘      │  └────────┬────────┘   │
         │               │           │            │
         ▼               │           ▼            │
┌─────────────────┐      │  ┌─────────────────┐   │
│  Frontend Pod   │      │  │  Backend Pod    │   │
│  ┌───────────┐  │      │  │  ┌───────────┐  │   │
│  │   Nginx   │  │      │  │  │  Node.js  │  │   │
│  │  Serving  │  │      │  │  │  Express  │  │   │
│  │  React    │  │      │  │  │    API    │  │   │
│  │   App     │  │      │  │  └─────┬─────┘  │   │
│  └───────────┘  │      │  │        │        │   │
│                 │      │  │  MongoDB Client │   │
│  Environment:   │      │  │  Connection     │   │
│  REACT_APP_     │      │  │  String         │   │
│  BACKEND_URL=   │      │  └────────┬────────┘   │
│  https://todo.  │      │           │            │
│  tarang.cloud/  │      │           │            │
│  api/tasks      │      │           │            │
└─────────────────┘      │           │            │
         │               │           │            │
         │ HTTPS API Call│           │            │
         │ (via ALB)     │           │            │
         └───────────────┘           │            │
                                     │            │
                                     ▼            │
                            ┌─────────────────┐   │
                            │  MongoDB        │   │
                            │  Service        │   │
                            │  (ClusterIP)    │   │
                            │  Port: 27017    │   │
                            └────────┬────────┘   │
                                     │            │
                                     ▼            │
                            ┌─────────────────┐   │
                            │  MongoDB Pod    │   │
                            │  (StatefulSet)  │   │
                            │  ┌───────────┐  │   │
                            │  │  MongoDB  │  │   │
                            │  │   4.4.x   │  │   │
                            │  └─────┬─────┘  │   │
                            │        │        │   │
                            │  Persistent     │   │
                            │  Volume Claim   │   │
                            │  (10Gi)         │   │
                            └────────┬────────┘   │
                                     │            │
                                     ▼            │
                            ┌─────────────────┐   │
                            │  EBS Volume     │   │
                            │  (gp3)          │   │
                            │  Data Storage   │   │
                            └─────────────────┘   │
                                                  │
        ┌─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          ARGOCD GITOPS                                   │
│                    (Continuous Deployment)                               │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  ArgoCD Image Updater                                          │    │
│  │  Monitors ECR repositories for new images                      │    │
│  │  - frontend: YYYYMMDD-BUILD format                             │    │
│  │  - backend: YYYYMMDD-BUILD format                              │    │
│  │  Auto-updates deployments in cluster when new images detected  │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  Applications:                                                           │
│  ├─ frontend-app   (three-tier-fe repo)                                 │
│  ├─ backend-app    (three-tier-be repo)                                 │
│  ├─ database-app   (infrastructure repo)                                │
│  └─ ingress-app    (infrastructure repo)                                │
└─────────────────────────────────────────────────────────────────────────┘

**Security Features:**
├─ HTTPS/TLS Encryption (End-to-End)
├─ AWS Certificate Manager (Free SSL Certificate)
├─ Automatic HTTP → HTTPS Redirect
├─ Private EKS Cluster (No Direct Internet Access)
├─ ALB in Public Subnets (Internet-Facing)
├─ Application Pods in Private Subnets
└─ ECR Image Scanning (Trivy + SonarQube)
```

**Key Architectural Highlights:**

1. **SSL/TLS Termination at ALB:**
   - HTTPS connections terminate at the AWS ALB
   - ALB uses ACM-managed wildcard certificate (`*.tarang.cloud`)
   - Traffic within VPC remains unencrypted (HTTP) for performance

2. **Host-Based & Path-Based Routing:**
   - Host: `todo.tarang.cloud` ensures requests reach correct application
   - Path `/api/*` routes to backend service
   - Path `/*` (default) routes to frontend service

3. **Frontend-Backend Communication:**
   - Frontend makes HTTPS API calls back through the ALB
   - Environment variable: `REACT_APP_BACKEND_URL=https://todo.tarang.cloud/api/tasks`
   - Ensures same-origin policy compliance and avoids CORS issues

4. **GitOps Workflow:**
   - ArgoCD monitors 4 separate applications
   - Image Updater automatically detects new ECR images
   - Zero-touch deployments via Git commit updates

5. **Data Persistence:**
   - MongoDB uses StatefulSet with PersistentVolumeClaim
   - EBS gp3 volumes provide durable storage
   - Data survives pod restarts and rescheduling

**Access URL:** https://todo.tarang.cloud

---

This project follows a **microservices architecture** with three separate repositories:

#### Infrastructure Repository
**Repository:** [End-to-End-Kubernetes-Three-Tier-DevSecOps-Project](https://github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project)
- AWS infrastructure (EKS, Jenkins, networking)
- Kubernetes manifests for all services
- ArgoCD GitOps configurations
- Monitoring setup

#### Frontend Microservice
**Repository:** [three-tier-fe](https://github.com/uditmishra03/three-tier-fe)
- Technology: ReactJS 17 with modern UI design
- Web server: Nginx
- CI/CD: Independent Jenkins pipeline
- ECR: Dedicated `frontend` repository
- Tagging: Date-based format `YYYYMMDD-BUILD`

#### Backend Microservice
**Repository:** [three-tier-be](https://github.com/uditmishra03/three-tier-be)
- Technology: NodeJS/Express 4
- Database: MongoDB integration
- CI/CD: Independent Jenkins pipeline
- ECR: Dedicated `backend` repository
- Tagging: Date-based format `YYYYMMDD-BUILD`

**Architecture Layers:**

| Layer | Technology | Port | Repository | Purpose |
|-------|-----------|------|------------|---------|
| **Frontend** | React.js 17, Nginx | 3000 | [three-tier-fe](https://github.com/uditmishra03/three-tier-fe) | User interface, Material-UI components |
| **Backend** | Node.js/Express 4 | 3500 | [three-tier-be](https://github.com/uditmishra03/three-tier-be) | REST API, business logic |
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

**9. ArgoCD Image Updater Integration**

The pipeline **does not** update Kubernetes manifests. Instead:

- **Jenkins Role:** Build image → Push to ECR with semantic version tag (YYYYMMDD-BUILD)
- **ArgoCD Image Updater Role:** 
  - Monitors ECR repository for new image tags
  - Automatically detects latest semantic version
  - Updates the deployment with new image
  - Syncs changes to EKS cluster

**Post-Pipeline Actions:**
```groovy
post {
    success {
        echo "Pipeline completed successfully!"
        echo "Backend image built and pushed to ECR"
        echo "ArgoCD Image Updater will automatically detect and deploy the new image"
    }
    failure {
        echo "Pipeline failed. Please check the logs for details."
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
Docker Build → Tag (YYYYMMDD-BUILD) → Push to ECR
    ↓
ArgoCD Image Updater monitors ECR
    ↓
Detects new semantic version tag
    ↓
ArgoCD automatically updates deployment → Syncs to EKS
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

**Deployment Configuration:**
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

**Deployment Configuration:**
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

**End-to-End Automated Deployment Flow:**

```
┌─────────────────────────────────────────────────────────┐
│ 1. Developer Push                                       │
│    git push origin master (backend or frontend)         │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│ 2. GitHub Webhook                                       │
│    Triggers Jenkins pipeline                            │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│ 3. Jenkins Pipeline (5-8 minutes)                       │
│    Checkout → SonarQube → Build → Trivy → ECR Push     │
│    Creates tag: YYYYMMDD-XXX (zero-padded)             │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│ 4. AWS ECR                                              │
│    New image appears with date-based tag               │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼ (Wait up to 2 minutes)
┌─────────────────────────────────────────────────────────┐
│ 5. ArgoCD Image Updater (runs every 2 min)             │
│    - Queries ECR for new tags                           │
│    - Filters by regex: ^[0-9-]+$                        │
│    - Sorts: latest-first                                │
│    - Picks: YYYYMMDD-XXX (highest value)                │
│    - Updates: ArgoCD Application object                 │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│ 6. ArgoCD (auto-sync enabled)                           │
│    - Detects Application change                         │
│    - Syncs to cluster                                   │
│    - Updates Deployment with new image                  │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│ 7. Kubernetes                                           │
│    - RollingUpdate: Old pods terminate                  │
│    - New pods start with new image                      │
│    - Application updated!                               │
└─────────────────────────────────────────────────────────┘

Total Time: 7-10 minutes (5-8 min pipeline + 0-2 min Image Updater)
```

**Key Points:**
- **Jenkins:** Builds image and pushes to ECR (does NOT update K8s manifests)
- **ArgoCD Image Updater:** Monitors ECR and updates deployments automatically
- **No Git Write-Back:** Image Updater updates ArgoCD Application spec directly
- **Zero-Touch Deployment:** Fully automated from code push to production

**Verify Sync:**
```bash
argocd app get three-tier-app
argocd app sync three-tier-app  # Manual sync (rarely needed with auto-sync)
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
kubectl get pods -n default | grep prometheus
kubectl get svc -n default | grep prometheus
```

### 12.2 Access Prometheus

**Via LoadBalancer (Recommended):**
```bash
# Prometheus is already exposed via LoadBalancer
kubectl get svc stable-kube-prometheus-sta-prometheus -n default
```

**Access URL:** 
```
http://aba486402dcc7489db934c692c09b53f-468856416.us-east-1.elb.amazonaws.com:9090
```

**Or via Port Forward (for local access):**
```bash
kubectl port-forward -n default svc/prometheus-operated 9090:9090
```
Access: `http://localhost:9090`

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

### 13.1 Access Grafana

**Via LoadBalancer (Recommended):**
```bash
# Grafana is already exposed via LoadBalancer
kubectl get svc stable-grafana -n default
```

**Access URL:**
```
http://a2c6af4284b0a492ca5361c0f803d6d2-1545715117.us-east-1.elb.amazonaws.com
```

**Get Admin Password:**
```bash
kubectl get secret -n default stable-grafana -o jsonpath="{.data.admin-password}" | base64 -d
echo
```

**Login Credentials:**
- Username: `admin`
- Password: (from command above)

**Or via Port Forward (for local access):**
```bash
kubectl port-forward -n default svc/stable-grafana 3000:80
```
Access: `http://localhost:3000`

### 13.2 Configure Prometheus Data Source

Before importing dashboards, add Prometheus as a data source:

1. **Login to Grafana** using the URL above
2. **Go to Configuration** (gear icon) → **Data Sources**
3. **Click "Add data source"**
4. **Select "Prometheus"**
5. **Configure:**
   - Name: `Prometheus`
   - URL: `http://prometheus-operated:9090`
   - Access: `Server (default)`
6. **Click "Save & Test"** - should show "Data source is working"

### 13.3 Import Kubernetes Dashboards

Import pre-built Kubernetes monitoring dashboards:

1. **Click "+" (plus icon) → Import**
2. **Enter Dashboard ID** and click **Load**:
   - **15760** - Kubernetes / Views / Global
   - **15761** - Kubernetes / Views / Namespaces
   - **15762** - Kubernetes / Views / Pods
   - **6417** - Kubernetes Cluster Monitoring (via Prometheus)
   - **13770** - Kubernetes Cluster (Prometheus)
3. **Select Prometheus data source** from dropdown
4. **Click Import**
5. **Repeat for each dashboard ID**

**Recommended Dashboards:**

| Dashboard ID | Name | Purpose |
|--------------|------|----------|
| 15760 | Kubernetes / Views / Global | Cluster overview |
| 15761 | Kubernetes / Views / Namespaces | Namespace-level metrics |
| 15762 | Kubernetes / Views / Pods | Pod-level details |
| 6417 | Kubernetes Cluster Monitoring | Complete cluster health |
| 13770 | Kubernetes Cluster | Node and pod metrics |
| 315 | Kubernetes cluster monitoring | Alternative cluster view |

### 13.4 Current Dashboards

Pre-installed dashboards from kube-prometheus-stack:
- **Kubernetes / Compute Resources / Cluster**
- **Kubernetes / Compute Resources / Namespace (Pods)**
- **Kubernetes / Compute Resources / Node (Pods)**
- **Node Exporter / Nodes**

### 13.3 Planned Enhancements 🚀

The current monitoring setup provides basic infrastructure metrics. For planned enhancements including:
- Application-specific dashboards (Frontend, Backend, Database)
- Custom metrics integration
- Advanced alerting rules
- Notification channels (Slack, Email, PagerDuty)
- SLO/SLI dashboards
- Business metrics tracking

**See detailed implementation plans with code examples and timelines:**
📋 **[FUTURE-ENHANCEMENTS.md](./FUTURE-ENHANCEMENTS.md#5--prometheus--grafana-production-setup)** - Section 5: Prometheus & Grafana Production Setup

---

## 14. Jenkins Enhancements (Planned)

### 14.1 Current Pipeline Limitations

- ⚠️ Sequential stage execution
- ⚠️ No automated rollback mechanism
- ⚠️ Limited security scanning options
- ⚠️ Manual intervention required for failures
- ⚠️ No deployment notifications

### 14.2 Planned Improvements 🚀

Multiple enhancements are planned to transform the Jenkins pipeline into a production-grade CI/CD system:

- **Parallel Execution** - 30-40% faster builds
- **Automated Rollback** - Automatic recovery from failed deployments
- **Enhanced Security Scanning** - OWASP, Snyk, Checkov, Git Secrets
- **Notification Integrations** - Slack, Email, PagerDuty
- **Advanced Deployments** - Blue-Green, Canary strategies
- **Performance Optimization** - Docker caching, parallel testing
- **Compliance & Auditing** - Image signing, SBOM generation

**See detailed implementation with complete code examples and roadmap:**
📋 **[FUTURE-ENHANCEMENTS.md](./FUTURE-ENHANCEMENTS.md#6--jenkins-pipeline-enhancements)** - Section 6: Jenkins Pipeline Enhancements

---

## 15. Troubleshooting and Maintenance

### 15.1 Common Issues & Solutions

#### **Issue: Pods in CrashLoopBackOff**
```bash
# Check pod status
kubectl get pods -n three-tier

# View pod logs
kubectl logs <pod-name> -n three-tier

# Describe pod for events
kubectl describe pod <pod-name> -n three-tier

# Common causes:
# - Image pull errors → Check ECR credentials
# - Application errors → Check environment variables
# - Resource limits → Increase CPU/memory limits
```

#### **Issue: Jenkins Pipeline Fails at ECR Push**
```bash
# Solution: Refresh ECR credentials on Jenkins server
ssh ubuntu@<jenkins-ip>
aws ecr get-login-password --region us-east-1

# Or update ECR secret in Kubernetes
kubectl delete secret ecr-registry-secret -n three-tier
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=<account-id>.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password) \
  --namespace=three-tier
```

#### **Issue: ArgoCD Not Syncing**
```bash
# Check ArgoCD application status
argocd app get three-tier-app

# Manual sync
argocd app sync three-tier-app

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
```

#### **Issue: Load Balancer Not Working**
```bash
# Check ingress
kubectl get ingress -n three-tier
kubectl describe ingress mainlb -n three-tier

# Check ALB controller
kubectl get pods -n kube-system | grep aws-load-balancer

# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

#### **Issue: Database Connection Failures**
```bash
# Check MongoDB pod
kubectl get pod -n three-tier | grep mongodb

# Test connection from backend pod
kubectl exec -it <backend-pod> -n three-tier -- sh
nc -zv mongodb-svc 27017

# Verify secrets
kubectl get secret mongo-sec -n three-tier -o yaml
```

### 15.2 Maintenance Tasks

#### **Regular Maintenance (Weekly)**
```bash
# Update ECR credentials
kubectl delete secret ecr-registry-secret -n three-tier
# Recreate with fresh token

# Check resource usage
kubectl top nodes
kubectl top pods -n three-tier

# Review pod logs for errors
kubectl logs -n three-tier --tail=100 deployment/api
```

#### **Monthly Maintenance**
```bash
# Update EKS cluster
eksctl upgrade cluster --name three-tier-cluster

# Update Helm charts
helm repo update
helm upgrade stable prometheus-community/kube-prometheus-stack -n default

# Review and cleanup unused images
aws ecr list-images --repository-name backend
aws ecr batch-delete-image --repository-name backend --image-ids imageTag=old-tag
```

#### **Backup Procedures**
```bash
# Backup MongoDB data
kubectl exec -n three-tier deployment/mongodb -- mongodump --out /backup

# Backup Kubernetes manifests (already in Git)
git pull

# Export ArgoCD applications
argocd app get three-tier-app -o yaml > argocd-backup.yaml
```

### 15.3 Monitoring & Alerts

**Key Metrics to Monitor:**
- Pod restart counts
- Resource utilization (CPU/Memory)
- Application error rates
- API response times
- Database connection pool

**Health Check Endpoints:**
```bash
# Backend health
curl http://<alb-dns>/healthz
curl http://<alb-dns>/ready

# Prometheus
curl http://<prometheus-url>/-/healthy

# Grafana
curl http://<grafana-url>/api/health
```

### 15.4 Log Locations

| Component | Location |
|-----------|----------|
| Jenkins | `/var/lib/jenkins/jobs/<job-name>/builds/<build-number>/log` |
| SonarQube | `docker logs sonar` |
| Kubernetes Pods | `kubectl logs <pod-name> -n three-tier` |
| ArgoCD | `kubectl logs -n argocd deployment/argocd-server` |
| Prometheus | `kubectl logs -n default prometheus-stable-kube-prometheus-sta-prometheus-0` |

### 15.5 Disaster Recovery

**EKS Cluster Failure:**
```bash
# Recreate cluster
eksctl create cluster --name three-tier-cluster --config-file cluster-config.yaml

# Redeploy applications via ArgoCD
argocd app sync three-tier-app --force
```

**Data Loss:**
```bash
# Restore from MongoDB backup
kubectl exec -n three-tier deployment/mongodb -- mongorestore /backup
```

---

## 16. References and Best Practices

### 16.1 Quick Command Reference

#### **AWS CLI**
```bash
# Configure
aws configure

# ECR Login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# List ECR images
aws ecr list-images --repository-name backend
```

#### **kubectl**
```bash
# Context
kubectl config current-context
kubectl config use-context <context-name>

# Resources
kubectl get all -n three-tier
kubectl get pods -n three-tier -w
kubectl logs -f <pod-name> -n three-tier
kubectl exec -it <pod-name> -n three-tier -- sh
kubectl describe pod <pod-name> -n three-tier

# Deployments
kubectl rollout status deployment/<name> -n three-tier
kubectl rollout history deployment/<name> -n three-tier
kubectl rollout undo deployment/<name> -n three-tier

# Secrets
kubectl create secret generic <name> --from-literal=key=value -n three-tier
kubectl get secret <name> -n three-tier -o yaml
```

#### **Helm**
```bash
# Repository
helm repo add <name> <url>
helm repo update

# Install/Upgrade
helm install <release> <chart> -n <namespace>
helm upgrade <release> <chart> -n <namespace>
helm list -n <namespace>

# Uninstall
helm uninstall <release> -n <namespace>
```

#### **ArgoCD**
```bash
# Login
argocd login <server>

# Applications
argocd app list
argocd app get <app-name>
argocd app sync <app-name>
argocd app history <app-name>
argocd app rollback <app-name> <revision>
```

### 16.2 Security Best Practices

#### **Container Security**
- ✅ Use minimal base images (alpine, distroless)
- ✅ Run containers as non-root user
- ✅ Scan images for vulnerabilities (Trivy)
- ✅ Sign container images (Cosign)
- ✅ Implement image pull policies

#### **Kubernetes Security**
- ✅ Enable RBAC
- ✅ Use Network Policies for pod-to-pod communication
- ✅ Implement Pod Security Standards
- ✅ Store secrets in AWS Secrets Manager or Vault
- ✅ Enable audit logging

#### **CI/CD Security**
- ✅ Use separate credentials for different environments
- ✅ Rotate secrets regularly
- ✅ Implement approval gates for production
- ✅ Scan code for secrets before commit
- ✅ Use immutable build artifacts

#### **AWS Security**
- ✅ Enable MFA on all accounts
- ✅ Use IAM roles instead of access keys
- ✅ Enable CloudTrail for audit logs
- ✅ Implement least privilege access
- ✅ Enable VPC Flow Logs

### 16.3 Performance Optimization

**Application Level:**
- Use connection pooling for databases
- Implement caching (Redis)
- Optimize Docker images (multi-stage builds)
- Use CDN for static assets

**Kubernetes Level:**
- Set appropriate resource requests/limits
- Use Horizontal Pod Autoscaler (HPA)
- Implement readiness/liveness probes
- Use node affinity for workload placement

**Infrastructure Level:**
- Use appropriate EC2 instance types
- Enable EBS volume optimization
- Use Application Load Balancer caching
- Implement CloudFront for global distribution

### 16.4 Cost Optimization

```bash
# Stop EKS cluster (non-production)
eksctl delete cluster --name three-tier-cluster

# Stop Jenkins server
aws ec2 stop-instances --instance-ids <instance-id>

# Delete unused ECR images
aws ecr list-images --repository-name backend --filter tagStatus=UNTAGGED --query 'imageIds[*]' --output json | jq -r '[.[].imageDigest] | map("imageDigest=" + .) | join(" ")' | xargs -n 1 aws ecr batch-delete-image --repository-name backend --image-ids

# Use Spot Instances for EKS nodes
eksctl create nodegroup --cluster=three-tier-cluster --spot
```

### 16.5 Additional Resources

**Official Documentation:**
- [AWS EKS](https://docs.aws.amazon.com/eks/)
- [Kubernetes](https://kubernetes.io/docs/)
- [Jenkins](https://www.jenkins.io/doc/)
- [ArgoCD](https://argo-cd.readthedocs.io/)
- [Prometheus](https://prometheus.io/docs/)
- [Grafana](https://grafana.com/docs/)

**Learning Resources:**
- [Kubernetes Patterns](https://k8spatterns.io/)
- [12-Factor App](https://12factor.net/)
- [GitOps Principles](https://opengitops.dev/)

**Community:**
- [CNCF Slack](https://slack.cncf.io/)
- [Kubernetes Forum](https://discuss.kubernetes.io/)
- [DevOps Stack Exchange](https://devops.stackexchange.com/)

### 16.6 Project Maintenance

**Repository:** [github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project](https://github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project)

**Contributions:** Pull requests welcome!

**Issues:** Report bugs or request features via GitHub Issues

**License:** MIT License

---

**🎉 End of Documentation**

**Last Updated:** November 15, 2025  
**Version:** 1.0  
**Estimated Read Time:** ~12-15 minutes

For questions or support, please open an issue on GitHub or contact the maintainers.

---
