# Three-Tier Web Application Deployment on AWS EKS using AWS EKS, ArgoCD, Prometheus, Grafana, and Jenkins
[![LinkedIn](https://img.shields.io/badge/Connect%20with%20me%20on-LinkedIn-blue.svg)](https://www.linkedin.com/in/uditmishra03/)
[![GitHub](https://img.shields.io/badge/github-repo-blue?logo=github)](https://github.com/uditmishra03)
[![AWS](https://img.shields.io/badge/AWS-%F0%9F%9B%A1-orange)](https://aws.amazon.com)
[![Terraform](https://img.shields.io/badge/Terraform-%E2%9C%A8-lightgrey)](https://www.terraform.io)

![Three-Tier Banner](assets/Three-Tier.gif)

Welcome to the Three-Tier Web Application Deployment project! 🚀

This repository hosts the implementation of a Three-Tier Web App using ReactJS, NodeJS, and MongoDB, deployed on AWS EKS. The project covers a wide range of tools and practices for a robust and scalable DevOps setup.

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
