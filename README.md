# Three-Tier Web Application Deployment on AWS EKS using AWS EKS, ArgoCD, Prometheus, Grafana, and Jenkins
[![LinkedIn](https://img.shields.io/badge/Connect%20with%20me%20on-LinkedIn-blue.svg)](https://www.linkedin.com/in/uditmishra03/)
[![GitHub](https://img.shields.io/badge/github-repo-blue?logo=github)](https://github.com/uditmishra03)
[![AWS](https://img.shields.io/badge/AWS-%F0%9F%9B%A1-orange)](https://aws.amazon.com)
[![Terraform](https://img.shields.io/badge/Terraform-%E2%9C%A8-lightgrey)](https://www.terraform.io)

## 📖 Project Overview

This project demonstrates a **production-grade DevSecOps implementation** of a three-tier microservices application (React frontend, Node.js backend, MongoDB database) on **AWS EKS**. It showcases end-to-end automation with **Jenkins CI/CD pipelines**, **security scanning** (SonarQube, Trivy), **GitOps deployment** via ArgoCD Image Updater, and comprehensive **monitoring** using Prometheus and Grafana. Infrastructure is provisioned using **Terraform**, following industry best practices for scalability, security, and maintainability.

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
