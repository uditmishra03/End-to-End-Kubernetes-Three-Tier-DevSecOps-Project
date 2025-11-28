# Three-Tier Web Application Deployment on AWS EKS using AWS EKS, ArgoCD, Prometheus, Grafana, and Jenkins
[![LinkedIn](https://img.shields.io/badge/Connect%20with%20me%20on-LinkedIn-blue.svg)](https://www.linkedin.com/in/uditmishra03/)
[![GitHub](https://img.shields.io/badge/github-repo-blue?logo=github)](https://github.com/uditmishra03)
[![AWS](https://img.shields.io/badge/AWS-%F0%9F%9B%A1-orange)](https://aws.amazon.com)
[![Terraform](https://img.shields.io/badge/Terraform-%E2%9C%A8-lightgrey)](https://www.terraform.io)

## 📖 Project Overview

This project demonstrates a **production-grade DevSecOps implementation** of a three-tier microservices application (React frontend, Node.js backend, MongoDB database) on **AWS EKS**. It showcases end-to-end automation with **Jenkins CI/CD pipelines**, **security scanning** (SonarQube, Trivy), **GitOps deployment** via ArgoCD Image Updater, and comprehensive **monitoring** using Prometheus and Grafana. Infrastructure is provisioned using **Terraform**, following industry best practices for scalability, security, and maintainability.

## 🎬 Demo Videos

Watch the complete project walkthrough and CI/CD pipeline demonstrations:

1. **📹 [Complete Architecture Walkthrough](https://youtu.be/UDUG4bSSoV0?si=nEWenIlAgi_nv0yh)** - Full system architecture overview and component walkthrough
2. **📹 [Three-Tier Project | Backend Application Walkthrough - Complete CI/CD Pipeline](https://youtu.be/KwXfFxuK1MM)** - Backend CI/CD demonstration with Jenkins, security scanning, and automated deployment
3. **📹 [Frontend CI/CD Pipeline Demo](https://youtu.be/W7wGFY9dyYU?si=96heJTQO0ld49pRq)** *(No audio)* - Frontend code changes triggering zero-downtime deployments

**What's Covered in the Demos:**
- Live code commits triggering automated CI/CD pipelines
- Jenkins pipeline execution with security scanning (SonarQube + Trivy)
- Docker image builds and ECR push
- ArgoCD GitOps automated deployments
- Zero-downtime rolling updates on EKS
- Real-time monitoring with Prometheus & Grafana

## 📸 Pipeline Screenshots

Complete visual walkthrough of the CI/CD pipeline execution:

### Jenkins CI/CD Pipeline
![Jenkins Pipeline Overview](assets/screenshots/Jenkins_all_mbp.png)
*Jenkins dashboard showing all configured pipelines*

![Frontend Pipeline Execution](assets/screenshots/jenkins_fe_mbp.png)
![Frontend Pipeline Execution](assets/screenshots/jenkins_fe_mbp_stages.png)
![Frontend Pipeline Execution](assets/screenshots/Jenkins_console_logs.png)
*Frontend pipeline stages: Code checkout, SonarQube analysis, Trivy scan, Docker build*

![Backend Pipeline Execution](assets/screenshots/jenkins_be_mbp.png)
![Backend Pipeline Execution](assets/screenshots/jenkins_be_mbp_stages.png)
*Backend pipeline stages: Code checkout, SonarQube analysis, Trivy scan, Docker build*

### Security Scanning
![SonarQube Analysis](assets/screenshots/sonar_proj.png)
*SonarQube code quality and security analysis results*

![Trivy Security Scan](assets/screenshots/trivy.png)
*Trivy vulnerability scanning for Docker images*

### Docker & ECR
![Docker Build Process](assets/screenshots/docker_build_push.png)
*Docker image build with semantic versioning (YYYYMMDD-BUILD)*

![ECR Repository](assets/screenshots/ecr_fe.png)
![ECR Repository](assets/screenshots/ecr_be.png)
*AWS ECR showing frontend and backend image repositories*

![Image Push Success](assets/screenshots/img_push_success.png)
*Successful Docker image push to ECR with version tags*

### ArgoCD GitOps Deployment
![ArgoCD Dashboard](assets/screenshots/argo_all_apps.png)
*ArgoCD applications overview - Frontend, Backend, Database, Ingress*

![Frontend Application Sync Status](assets/screenshots/argo_fe.png)
*ArgoCD showing healthy and synced application status*

![Backend Application Sync Status](assets/screenshots/argo_be.png)
*ArgoCD showing healthy and synced application status*

![Database Application Sync Status](assets/screenshots/argo_db.png)
*ArgoCD showing healthy and synced application status*

![Backend Application Sync Status](assets/screenshots/argo_ingress.png)
*ArgoCD showing healthy and synced application status*

![Image Updater](assets/screenshots/image_updater.png)

*ArgoCD Image Updater detecting and deploying new ECR images*

![Deployment Details](assets/screenshots/pod_status.png)

*Kubernetes deployment details with pod status*

### Kubernetes Cluster
![EKS Cluster Nodes](assets/screenshots/nodes.png)

*EKS cluster nodes and resource utilization*

![Running Pods](assets/screenshots/pod_status.png)

*All pods running in three-tier namespace*

![Services & Ingress](assets/screenshots/svc_ing.png)

*Kubernetes services and ALB ingress configuration*

### Monitoring Stack
![Prometheus Targets](assets/screenshots/prometheus_2.png)
*Prometheus targets showing all monitored endpoints*

![Grafana Dashboard](assets/screenshots/grafana_db_00.png)
*Grafana Dashboard 315 - Kubernetes cluster monitoring*

![Grafana Dashboard](assets/screenshots/grafana_db_01.png)
*Grafana Dashboard 315 - Kubernetes cluster monitoring*

![Grafana Dashboard](assets/screenshots/grafana_db_1.png)
*Grafana Dashboard 315 - Kubernetes cluster monitoring*

![Grafana Dashboard](assets/screenshots/grafana_db_3.png)
*Grafana Dashboard 315 - Kubernetes cluster monitoring*

![Grafana Dashboard](assets/screenshots/grafana_db_4.png)
*Grafana Dashboard 315 - Kubernetes cluster monitoring*

![Grafana Dashboard](assets/screenshots/grafana_db_5.png)
*Grafana Dashboard 315 - Kubernetes cluster monitoring*

![Pod Monitoring](assets/screenshots/grafana_db_0.png)
*Pod-level CPU, memory, and network metrics*

### Application Demo
![Frontend Application](assets/screenshots/application.png)
*Live TO-DO application with DevSecOps demo banner*

![Backend API](assets/screenshots/app_be.png)

![Backend API](assets/screenshots/app_be_2.png)

*Backend API version endpoint response*

---

## 🚀 Getting Started

**New to this project?** Follow these steps:

1. **[Getting Started Guide](docs/GETTING-STARTED.md)** - Complete deployment from scratch (Steps 1-11)
2. **[Complete Documentation](docs/DOCUMENTATION.md)** - Detailed technical reference for each component
3. **[Architecture Diagrams](assets/)** - Visual system architecture (draw.io & Mermaid)

### Quick Links:
- 📖 [Getting Started Guide](docs/GETTING-STARTED.md) - **Start here for step-by-step setup**
- 📚 [Complete Documentation](docs/DOCUMENTATION.md) - In-depth technical details
- 🎯 [Future Enhancements](docs/FUTURE-ENHANCEMENTS.md) - Planned features
- 💰 [Cost Management](docs/AWS-COST-MANAGEMENT.md) - AWS cost optimization
- 🔧 [Troubleshooting](docs/DOCUMENTATION.md#15-troubleshooting-and-maintenance) - Common issues and fixes

---

## 🏗️ Architecture Overview

This project has evolved from a **monolithic architecture** to a **microservices architecture** for better scalability, independent deployments, and improved developer experience.

### Repository Structure (Microservices)

📦 **Infrastructure Repository (This repo):**
- AWS Infrastructure (Terraform, EKS, Jenkins)
- Kubernetes Manifests
- ArgoCD GitOps Configuration
- CI/CD Pipeline Scripts
- Monitoring & Observability Setup

🎨 **Frontend Microservice:**
- Repository: [three-tier-fe](https://github.com/uditmishra03/three-tier-fe)
- Technology: ReactJS, Nginx
- Independent CI/CD Pipeline
- Dedicated ECR Repository

⚙️ **Backend Microservice:**
- Repository: [three-tier-be](https://github.com/uditmishra03/three-tier-be)
- Technology: NodeJS, Express, MongoDB
- Independent CI/CD Pipeline
- Dedicated ECR Repository

### Benefits of Microservices Architecture:
- ✅ Independent deployment cycles for frontend and backend
- ✅ Isolated CI/CD pipelines - changes in one service don't trigger builds in others
- ✅ Better scalability and resource management
- ✅ Improved developer experience and team autonomy
- ✅ Easier debugging and maintenance

### High-Level Architecture Flow:

```
Developer Code Push
        │
        ├─► GitHub (three-tier-fe) ──► Jenkins Pipeline ──► ECR (frontend) ──┐
        ├─► GitHub (three-tier-be) ──► Jenkins Pipeline ──► ECR (backend)  ──┤
        │                                                                    │
        └─► GitHub (Infrastructure) ──► ArgoCD ◄─── Image Updater ◄──────────┘
                                          │
                                          │ GitOps Deployment
                                          ▼
                                    AWS EKS Cluster
                                          │
                        ┌─────────────────┼─────────────────┐
                        ▼                 ▼                 ▼
                  Frontend Pods     Backend Pods     MongoDB Pods
                  (React/Nginx)     (Node/Express)   (Database)
                        │                 │                 │
                        └────────► ALB Ingress ◄───────────┘
                                          │
                                          ▼
                                    End Users

    Monitoring: Prometheus + Grafana ──► All Pods & Services
```

<details>
<summary>📐 <b>View Detailed System Architecture</b></summary>

For a comprehensive technical view including all components, namespaces, ports, services, and monitoring stack, see the [Complete System Architecture in DOCUMENTATION.md](docs/DOCUMENTATION.md#21-system-architecture).

The detailed architecture covers:
- Complete CI/CD pipeline flow with Jenkins stages
- ECR registry configuration and lifecycle policies
- ArgoCD GitOps setup with Image Updater
- Kubernetes cluster components (pods, services, ingress)
- Monitoring and observability stack
- End-to-end data flow from developer to end user

</details>

---

## Table of Contents
- [Architecture Overview](#️-architecture-overview)
- [Application Code](#application-code)
- [Jenkins Pipeline Code](#jenkins-pipeline-code)
- [Jenkins Server Terraform](#jenkins-server-terraform)
- [Kubernetes Manifests Files](#kubernetes-manifests-files)
- [Project Details](#project-details)

## Application Code
**Note:** The application code has been migrated to separate microservice repositories for independent development and deployment:

- **Frontend Application:** [three-tier-fe](https://github.com/uditmishra03/three-tier-fe) - ReactJS application with Nginx
- **Backend Application:** [three-tier-be](https://github.com/uditmishra03/three-tier-be) - NodeJS/Express API with MongoDB

This repository now focuses on infrastructure, CI/CD pipelines, and GitOps configurations.

## Jenkins Pipeline Code
In the `Jenkins-Pipeline-Code` directory, you'll find Jenkins pipeline scripts. These scripts automate the CI/CD process, ensuring smooth integration and deployment of your application.

## Jenkins Server Terraform
Explore the `Jenkins-Server-TF` directory to find Terraform scripts for setting up the Jenkins Server on AWS. These scripts simplify the infrastructure provisioning process.

## Kubernetes Manifests Files
The `Kubernetes-Manifests-Files` directory holds Kubernetes manifests for deploying your application on AWS EKS. Understand and customize these files to suit your project needs.

## Project Details
🛠️ **Tools Explored:**
- Terraform & AWS CLI for AWS infrastructure
- Jenkins, Sonarqube, Terraform, Kubectl, and more for CI/CD setup
- Helm, Prometheus, and Grafana for Monitoring
- ArgoCD for GitOps practices

🚢 **High-Level Overview:**
- IAM User setup & Terraform magic on AWS
- Jenkins deployment with AWS integration
- EKS Cluster creation & Load Balancer configuration
- Private ECR repositories for secure image management
- Helm charts for efficient monitoring setup
- GitOps with ArgoCD - the cherry on top!

📈 **The journey covered everything from setting up tools to deploying a Three-Tier app, ensuring data persistence, and implementing CI/CD pipelines.**

## Getting Started
To get started with this project, refer to our [Github](https://github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project) documentation that walks you through IAM user setup, infrastructure provisioning, CI/CD pipeline configuration, EKS cluster creation, and more.

## Contributing
We welcome contributions! If you have ideas for enhancements or find any issues, please open a pull request or file an issue.

## License
This project is licensed under the [MIT License](LICENSE).

Happy Coding! 🚀
