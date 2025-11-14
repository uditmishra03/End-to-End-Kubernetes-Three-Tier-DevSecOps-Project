# Ongoing Tasks - Three-Tier DevSecOps Project

**Last Updated:** November 15, 2025

---

## 🔄 In Progress

### 1. **Automated CI/CD with Webhook - Infinite Loop Prevention**
**Status:** 🟡 Testing Solution  
**Priority:** High  
**Assigned Date:** Nov 15, 2025

**Problem:**
- GitHub webhook triggers Jenkins on every push
- Jenkins pipeline was updating deployment.yaml files and pushing back to GitHub
- This created an infinite loop: Code push → Build → Deployment update → Triggers new build → Repeat
- Initial solution (commit message check with `NOT_BUILT` result) created clumsy build entries in Jenkins UI

**Solution Implemented:**
- Removed deployment file update stages from Jenkins MBP pipelines (currently commented out)
- Jenkins now only: Build → Scan → Push to ECR → Stop
- No git commits = No webhook loop ✅
- Clean, single build per actual code change

**Files Modified:**
- `Jenkins-Pipeline-Code/jenkinsfile_backend_mbp` - Commented out deployment update stage
- `Jenkins-Pipeline-Code/jenkinsfile_frontend_mbp` - Commented out deployment update stage

**Next Steps:**
1. Commit and push the commented-out Jenkinsfiles
2. Test webhook triggers - should see only ONE build per code change
3. Choose deployment update strategy:
   - **Option A (Manual):** Update deployment.yaml files manually when needed
   - **Option B (Automated):** Configure ArgoCD Image Updater for automatic updates

**Related Files:**
- `Kubernetes-Manifests-file/argocd-backend-app.yaml` (created, not applied)
- `Kubernetes-Manifests-file/argocd-frontend-app.yaml` (created, not applied)

**ArgoCD Image Updater:**
- Installed: ✅ (v0.12.2)
- Configured: ❌ (needs ECR credentials and Git write-back setup)

---

## ✅ Completed

### 1. **Infrastructure Setup**
**Completed:** Nov 15, 2025
- EKS cluster operational: `Three-Tier-K8s-EKS-Cluster`
- ECR repositories configured (Account ID: 296062548155)
- ALB Ingress Controller deployed
- ArgoCD installed and accessible

### 2. **Jenkins Pipeline Configuration**
**Completed:** Nov 15, 2025
- Standard pipelines working (Jenkinsfile-Backend, Jenkinsfile-Frontend)
- Multibranch pipelines created (jenkinsfile_backend_mbp, jenkinsfile_frontend_mbp)
- All stages functional: SonarQube, Trivy, Docker Build, ECR Push
- OWASP Dependency-Check disabled (NVD API issues)
- Trivy wrapped in catchError to prevent build failures

### 3. **ECR Authentication Issues**
**Completed:** Nov 15, 2025
- Fixed wrong AWS account ID (407622020962 → 296062548155)
- Updated all deployment manifests with correct registry
- Image pull working successfully

### 4. **Monitoring Stack**
**Completed:** Nov 15, 2025
- Grafana accessible with password: `QpuxKfZFFprkJQtaUT27z4tUmphYbkcBFx4q1zcK`
- Core metrics working (CPU: 17%, Memory: 47%)
- Dashboards 315 and 7249 configured
- Some filesystem metrics showing N/A (deferred)

### 5. **GitHub Webhook Integration**
**Completed:** Nov 15, 2025
- Webhook configured for automated builds
- Triggers working on every push
- URL: `http://54.164.105.186:8080/github-webhook/`

### 6. **Application Accessibility**
**Completed:** Nov 15, 2025
- Application accessible via ALB DNS
- Removed ingress host restriction
- Backend and frontend routing working
- ALB DNS: `k8s-threetie-mainlb-1dd958d0ec-128970382.us-east-1.elb.amazonaws.com`

---

## 📋 Backlog

### 1. **ArgoCD Image Updater Full Configuration**
**Priority:** Medium
**Description:**
- Configure ECR credentials for Image Updater
- Set up Git write-back credentials
- Apply ArgoCD application manifests
- Test automatic image updates
- Remove commented deployment update stages after confirmation

### 2. **OWASP Dependency-Check**
**Priority:** Low
**Description:**
- Resolve NVD API key integration issues
- Re-enable OWASP stage in pipelines

### 3. **Grafana Dashboard Optimization**
**Priority:** Low
**Description:**
- Fix filesystem metrics showing N/A
- Investigate missing total metrics
- Optimize dashboard queries

### 4. **Node.js Version Upgrade**
**Priority:** Low
**Description:**
- Upgrade from Node.js 14.0 to 14.17+ for SonarQube compatibility

---

## 🔧 Current Environment

**AWS:**
- Region: us-east-1
- EKS Cluster: Three-Tier-K8s-EKS-Cluster (v1.28.4)
- ECR Account: 296062548155
- Namespace: three-tier

**Jenkins:**
- Version: 2.536
- Instance: t2.2xlarge @ 54.164.105.186:8080
- Pipeline Type: Multibranch (migrated from standard)

**Repositories:**
- ECR Backend: `296062548155.dkr.ecr.us-east-1.amazonaws.com/backend`
- ECR Frontend: `296062548155.dkr.ecr.us-east-1.amazonaws.com/frontend`
- GitHub: `uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project`

**Security Tools:**
- SonarQube: 9.9.8
- Trivy: v0.67 (wrapped in catchError)
- OWASP: Disabled

**Monitoring:**
- Prometheus + Grafana
- Dashboards: 315 (Kubernetes cluster monitoring), 7249 (Node exporter)

---

## 📝 Notes

- **Jenkins MBP Setup:** Using "Multibranch Scan Webhook Trigger" plugin
- **Webhook Pattern:** Currently triggers on all pushes to master branch
- **Image Tagging:** Using Jenkins BUILD_NUMBER as image tags
- **Deployment Strategy:** GitOps with ArgoCD (manual sync for now)

---

## 🎯 Success Criteria for Current Task

- [ ] Single build per actual code change (no infinite loops)
- [ ] Clean Jenkins build history (no ABORTED/NOT_BUILT entries for automated commits)
- [ ] Automated deployment updates working (either manual or via ArgoCD Image Updater)
- [ ] End-to-end flow: Code push → Jenkins build → ECR push → Deployment update → ArgoCD sync

---

**Resume Point:** Test the webhook with commented-out deployment stages, verify single build, then decide between manual updates vs ArgoCD Image Updater.
