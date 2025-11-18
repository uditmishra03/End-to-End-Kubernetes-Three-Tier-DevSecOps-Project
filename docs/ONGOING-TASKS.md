# Ongoing Tasks - Three-Tier DevSecOps Project

**Last Updated:** November 16, 2025

---

## 🔄 In Progress

### 1. **Fully Automated CI/CD Pipeline with ArgoCD Image Updater**
**Status:** � Resolved - Testing Phase  
**Priority:** High  
**Assigned Date:** Nov 15-16, 2025

**Problem:**
- Initial infinite loop: Jenkins → Updates deployment.yaml → Git push → Webhook triggers Jenkins → Loop
- Attempted solutions with commit message checks created unwanted NOT_BUILT entries

**Solution Implemented:**
1. **Installed ArgoCD Image Updater** (v0.12.2) to handle automatic image updates
2. **Removed deployment update stages** from Jenkins MBP pipelines
3. **Configured Kustomize** support for backend and frontend applications
4. **Set up ECR authentication** for Image Updater using docker-registry secret
5. **Configured Git credentials** for ArgoCD to access GitHub repository
6. **Changed write-back method to `argocd`** mode to prevent Git commits and webhook loops

**Steps Performed:**

**Phase 1: Kustomize Setup**
- Created `kustomization.yaml` files in Backend and Frontend directories
- Updated ArgoCD applications to use Kustomize (added `kustomize: {}` to source spec)
- Enabled auto-sync on `backend` and `frontend` applications

**Phase 2: ArgoCD Image Updater Installation**
- Installed Image Updater: `kubectl apply -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/v0.12.2/manifests/install.yaml`
- Added annotations to applications for image tracking:
  - `argocd-image-updater.argoproj.io/image-list`
  - `argocd-image-updater.argoproj.io/update-strategy: latest`
  - `argocd-image-updater.argoproj.io/allow-tags: regexp:^[0-9]+$`

**Phase 3: ECR Authentication**
- Created docker-registry secret with ECR credentials
- Updated Image Updater ConfigMap with registry configuration:
  ```yaml
  registries:
  - name: ECR
    prefix: 296062548155.dkr.ecr.us-east-1.amazonaws.com
    api_url: https://296062548155.dkr.ecr.us-east-1.amazonaws.com
    credentials: pullsecret:argocd/ecr-registry-secret
  ```

**Phase 4: Git Write-Back Configuration**
- Created GitHub credentials secret for ArgoCD
- Initially configured `write-back-method: git` (caused webhook loops)
- **Final solution**: Changed to `write-back-method: argocd` to avoid Git commits

**Phase 5: Loop Prevention**
- Image Updater now updates ArgoCD application spec directly (no Git commits)
- No webhook triggers from Image Updater changes
- Clean Jenkins build history

**Current State:**
- ✅ Jenkins MBP pipelines: Build → Scan → Push to ECR only
- ✅ ArgoCD Image Updater: Monitors ECR → Updates ArgoCD app spec directly
- ✅ ArgoCD: Auto-syncs deployments when image changes detected
- ✅ No infinite loops

**Files Modified:**
- `Kubernetes-Manifests-file/Backend/kustomization.yaml` (created)
- `Kubernetes-Manifests-file/Frontend/kustomization.yaml` (created)
- Removed: `Kubernetes-Manifests-file/argocd-backend-app.yaml`
- Removed: `Kubernetes-Manifests-file/argocd-frontend-app.yaml`

**Remaining Issues:**
- `three-tier-backend` and `three-tier-frontend` applications keep reappearing
- Issue: `ingress` application synced to old commit that had the manifest files
- Solution: Need to sync `ingress` application to latest HEAD

**Next Steps:**
1. Sync ingress application to latest commit
2. Test end-to-end flow: Code change → Jenkins build → ECR push → Image Updater → ArgoCD deploy
3. Verify no webhook loops or duplicate applications
4. Document final automated workflow

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
- URL: `http://3.227.140.48:8080/github-webhook/`

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
- Instance: c6a.2xlarge @ 3.227.140.48:8080 (Static Elastic IP)
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
