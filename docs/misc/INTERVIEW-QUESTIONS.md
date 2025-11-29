# Senior DevOps / DevOps Lead Interview Guide
# Three-Tier DevSecOps Kubernetes Project on AWS EKS

## 📋 Document Purpose

This comprehensive interview preparation guide is designed for **Senior DevOps Engineer** and **DevOps Lead** positions at product-based companies. It provides:

- ✅ **80+ real-world questions** based on this project's exact implementation
- ✅ **Concise answers** for quick responses during interviews
- ✅ **Deep dive explanations** demonstrating senior-level understanding
- ✅ **Follow-up questions** with detailed answers to showcase expertise
- ✅ **Code/configuration references** for technical credibility
- ✅ **Trade-off discussions** showing architectural decision-making
- ✅ **Production readiness considerations** for scaling to enterprise

**Project Stack:** Jenkins CI/CD | AWS EKS | ECR | ArgoCD + Image Updater | ALB Ingress | Prometheus/Grafana | Terraform | eksctl | SonarQube | Trivy | MongoDB | React | Node.js/Express

---

## 📚 Table of Contents

1. [Architecture & System Design](#1-architecture--system-design)
2. [CI/CD Pipelines (Jenkins)](#2-cicd-pipelines-jenkins)
3. [GitOps with ArgoCD & Image Updater](#3-gitops-with-argocd--image-updater)
4. [Kubernetes & AWS EKS](#4-kubernetes--aws-eks)
5. [Networking & AWS ALB Ingress](#5-networking--aws-alb-ingress)
6. [Observability (Prometheus & Grafana)](#6-observability-prometheus--grafana)
7. [Security & Compliance](#7-security--compliance)
8. [Infrastructure as Code (Terraform)](#8-infrastructure-as-code-terraform)
9. [Docker & Container Management](#9-docker--container-management)
10. [Data Persistence & Backup](#10-data-persistence--backup)
11. [DNS & Certificate Management](#11-dns--certificate-management)
12. [Cost Optimization](#12-cost-optimization)
13. [Reliability & High Availability](#13-reliability--high-availability)
14. [Operations & Maintenance](#14-operations--maintenance)
15. [Troubleshooting & Debugging](#15-troubleshooting--debugging)
16. [Scaling & Production Readiness](#16-scaling--production-readiness)
17. [Leadership & Team Collaboration](#17-leadership--team-collaboration)

---

---

## 1) Architecture & System Design

### Q1.1: Walk me through the complete end-to-end architecture of this project.

**Concise Answer:**
- **Three-repository microservices**: Infrastructure repo (Terraform, K8s manifests, ArgoCD config), `three-tier-fe` (React + Nginx), `three-tier-be` (Node.js/Express + MongoDB)
- **CI/CD**: Jenkins Multibranch Pipelines with webhooks → 4-stage pipeline (SonarQube, Trivy scans, Docker build, ECR push)
- **GitOps**: ArgoCD + Image Updater auto-deploys from ECR using date-based tags (`YYYYMMDD-BUILD`)
- **Infrastructure**: Terraform (VPC, Jenkins EC2, ECR, IAM), eksctl (EKS cluster), kubectl/Helm (apps)
- **Networking**: AWS ALB Ingress Controller with shared ALB, path-based routing, HTTPS/TLS via ACM
- **Monitoring**: Prometheus (20Gi PVC) + Grafana (10Gi PVC) exposed via ALB paths
- **DNS**: Hostinger manages `tarang.cloud` with CNAMEs to ALB DNS

**Deep Dive Explanation:**

This is a production-grade microservices platform demonstrating DevSecOps best practices:

**Repository Strategy:**
- **Separation of concerns**: Infrastructure code, frontend, and backend are independently versioned and deployed
- **Benefits**: Parallel development, reduced blast radius, clear ownership, faster CI/CD (frontend change doesn't rebuild backend)
- **Trade-off**: Increased complexity in coordination, but managed via GitOps and semantic versioning

**CI/CD Flow (Detailed):**
1. Developer pushes code to `three-tier-fe` or `three-tier-be` → GitHub webhook triggers Jenkins
2. **Stage 1 - SonarQube Analysis**: Static code analysis, code coverage, vulnerability detection, Quality Gate enforcement
3. **Stage 2 - Trivy File Scan**: Scans source code dependencies for known CVEs (SCA - Software Composition Analysis)
4. **Stage 3 - Docker Build & Push**: Multi-stage Dockerfile, Docker Buildx for efficiency, ECR authentication via IAM role, tags image as `$(date +%Y%m%d)-${BUILD_NUMBER}` (e.g., `20241128-001`)
5. **Stage 4 - Trivy Image Scan**: Scans final container image for OS and application vulnerabilities

**GitOps Deployment Flow:**
1. Jenkins pushes tagged image to ECR repositories (`frontend`, `backend`)
2. ArgoCD Image Updater polls ECR every 2 minutes (configured via `argocd-image-updater-config/registries-configmap.yaml`)
3. Detects new tags matching regex `^[0-9-]+$` (date-based semantic versioning)
4. Updates Kubernetes Deployment manifests in-cluster or via write-back to Git
5. ArgoCD detects manifest change, syncs to EKS cluster (auto-sync enabled)
6. Kubernetes performs rolling update with health checks, zero-downtime deployment

**Infrastructure Layers:**
- **Layer 1 (Terraform)**: VPC (10.0.0.0/16), public subnet, IGW, route tables, security groups, Jenkins EC2 (c6a.2xlarge), EIP, ECR repositories, IAM roles/policies
- **Layer 2 (eksctl)**: EKS control plane, managed node groups, CloudFormation stacks, cluster IAM roles
- **Layer 3 (kubectl/Helm)**: ArgoCD, AWS Load Balancer Controller, Prometheus/Grafana, application deployments

**Network Architecture:**
- **External**: Hostinger DNS → ALB DNS → ALB (HTTPS/TLS) → Target Groups
- **Internal**: ALB → Kubernetes Ingress Controller → Services (ClusterIP) → Pods
- **Paths**: `/` → frontend, `/api` → backend, `/grafana` → Grafana, `/prometheus` → Prometheus
- **Health Checks**: ALB → `/healthz` endpoint on backend service

**Persistence Strategy:**
- **Stateful**: MongoDB PVC, Prometheus PVC (20Gi), Grafana PVC (10Gi), Jenkins EBS volume
- **Stateless**: Frontend/backend pods (ephemeral)
- **Survives cluster recreation**: All PVCs, Jenkins EBS
- **Changes on recreation**: ALB DNS, node IPs, instance IDs (documented in shutdown/startup procedures)

**Repo References:**
- Architecture diagrams: `docs/DOCUMENTATION.md` Section 2, `assets/system-architecture.mmd`
- Terraform: `Jenkins-Server-TF/*.tf`
- ArgoCD apps: `argocd-apps/*.yaml`
- Ingress: `k8s-infrastructure/ingress.yaml`, `k8s-infrastructure/monitoring/monitoring-ingress.yaml`

**Follow-up Q1.1a:** Why did you choose microservices architecture over a monolith for this project?

**Answer:**
Microservices provide:
1. **Independent scaling**: Frontend can scale horizontally without affecting backend resources
2. **Technology flexibility**: React for UI, Node.js for API - best tool for each job
3. **Faster CI/CD**: ~30-50s pipelines per service vs. minutes for monolith
4. **Team autonomy**: Frontend and backend teams can work independently
5. **Resilience**: Backend failure doesn't crash frontend (graceful degradation)
6. **Easier debugging**: Smaller codebases, clearer boundaries

Trade-offs accepted:
- Increased operational complexity (multiple deployments, service mesh considerations)
- Network latency between services
- Distributed tracing needs (would add Jaeger/OpenTelemetry in production)

For this demonstration project, the benefits outweigh the complexity, and it showcases industry-standard practices.

**Follow-up Q1.1b:** Explain the image tagging strategy and why it was chosen.

**Answer:**
Tags follow **date-based semantic versioning**: `YYYYMMDD-BUILD` (e.g., `20241128-001`)

**Why this format:**
1. **Human-readable**: Easy to identify when image was built
2. **Chronological ordering**: Natural sort order for Image Updater
3. **Traceability**: Correlates with Jenkins build numbers and Git commits
4. **ArgoCD regex compatibility**: `^[0-9-]+$` matches only semantic versions, prevents accidental `latest` tags
5. **Immutability**: Each build gets unique tag (no tag reuse)

**Alternative considered:**
- **Git SHAs**: More precise but less readable (e.g., `ab3f21c`)
- **Semantic versioning**: `v1.2.3` requires manual versioning logic
- **Hybrid**: Could tag with both date + SHA (e.g., `20241128-001-ab3f21c`)

**Image Updater configuration** (`argocd-apps/backend-app.yaml`):
```yaml
annotations:
  argocd-image-updater.argoproj.io/backend.allow-tags: regexp:^[0-9-]+$
  argocd-image-updater.argoproj.io/backend.update-strategy: latest
  argocd-image-updater.argoproj.io/backend.sort-tags: latest-first
```

This ensures only production-ready, date-tagged images are deployed, never development tags like `dev`, `test`, or `latest`.

**Follow-up Q1.1c:** How does the shared ALB reduce costs compared to separate load balancers?

**Answer:**
**Cost breakdown (us-east-1 pricing):**
- ALB: $0.0225/hour (~$16.20/month) + $0.008/LCU-hour
- Each additional ALB: +$16.20/month base cost

**With shared ALB:**
- Single ALB: $16.20/month + LCU charges
- Path-based routing: No additional ALB cost for frontend, backend, monitoring

**With separate ALBs (3 services):**
- 3 × $16.20 = $48.60/month base cost (3x more expensive)
- Plus 3× LCU charges

**Additional savings:**
1. **Single TLS certificate**: One ACM cert vs. three separate certs
2. **Simpler DNS management**: Two CNAME records vs. six records
3. **Reduced IP address usage**: One public IP vs. three
4. **Lower operational overhead**: One set of logs/metrics to monitor

**When to use separate ALBs:**
- Hard tenant isolation requirements
- Different security zones (public/private)
- Distinct SLA requirements
- Regulatory compliance (PCI-DSS segmentation)
- Multi-region active-active deployments

For this project, shared ALB is the optimal choice, saving ~$32/month while maintaining flexibility.

---

---

## 2) CI/CD Pipelines (Jenkins)

### Q2.1: Walk through the Jenkins CI/CD pipeline stages and explain the purpose of each.

**Concise Answer:**
- **4-stage pipeline** per service (frontend/backend): SonarQube Analysis → Trivy File Scan → Docker Build & Push → Trivy Image Scan
- **Runtime**: ~30-50 seconds per build (lightweight apps, cached layers)
- **Triggering**: GitHub webhooks trigger Jenkins Multibranch Pipeline on push to master
- **Image tagging**: `YYYYMMDD-BUILD` format (e.g., `20241128-001`)
- **Quality gates**: SonarQube blocks on code quality issues; Trivy blocks on HIGH/CRITICAL CVEs

**Deep Dive Explanation:**

**Stage 1: SonarQube Analysis & Quality Gate**
- **Purpose**: Static Application Security Testing (SAST) and code quality enforcement
- **Actions**: 
  - Analyzes code for bugs, code smells, security vulnerabilities
  - Checks test coverage against configured threshold
  - Enforces Quality Gate (default: no new bugs, coverage > 80%)
- **Configuration**: `sonar-project.properties` defines project key, source directories, exclusions
- **Blocking behavior**: Pipeline fails if Quality Gate fails (prevents deploying broken code)
- **Metrics tracked**: Maintainability rating, reliability rating, security rating, technical debt

**Stage 2: Trivy Filesystem Scan**
- **Purpose**: Software Composition Analysis (SCA) - detects vulnerabilities in dependencies *before* building image
- **Actions**:
  - Scans `package.json` / `package-lock.json` for known CVEs in Node.js dependencies
  - Uses Trivy's vulnerability database (updated daily from NVD, GitHub Security Advisories)
  - Generates JSON report with severity classification
- **Why scan before Docker build**: Fail fast - prevents wasting time building vulnerable images
- **Configuration**: `--severity HIGH,CRITICAL --exit-code 1` (blocks on high/critical findings)
- **Example findings**: Outdated Express versions with DoS vulnerabilities, prototype pollution issues

**Stage 3: Docker Build & Push to ECR**
- **Purpose**: Build production-ready container image and push to Amazon ECR
- **Actions**:
  1. Authenticate to ECR using IAM role attached to Jenkins EC2 instance (`aws ecr get-login-password`)
  2. Build multi-stage Dockerfile using **Docker Buildx** (faster builds, better caching)
  3. Tag image with date-based semantic version: `$(date +%Y%m%d)-${BUILD_NUMBER}`
     - Example: `123456789012.dkr.ecr.us-east-1.amazonaws.com/frontend:20241128-001`
  4. Push to ECR repositories (`frontend`, `backend`)
- **Optimization**: Buildx enables BuildKit features (parallel layer builds, improved caching)
- **Why date-based tags**: Human-readable, chronologically sortable, ArgoCD regex-compatible
- **Alternative tags considered**: Git SHAs (more precise), semantic versions (requires manual bump logic)

**Stage 4: Trivy Image Scan**
- **Purpose**: Scan the *final container image* for OS and application vulnerabilities
- **Actions**:
  - Pulls built image from ECR
  - Scans base image OS packages (Alpine/Ubuntu vulnerabilities)
  - Re-scans application dependencies in final image context
  - Checks for misconfigurations (exposed secrets, insecure permissions)
- **Why scan again after Stage 2**: Catches vulnerabilities introduced by base image or build process
- **Configuration**: Same `--severity HIGH,CRITICAL --exit-code 1` threshold
- **Report output**: JSON format stored as Jenkins artifact for audit trail

**Pipeline Performance:**
- **Typical runtime**: 30-50 seconds (small apps, cached base images)
- **Breakdown**: SonarQube ~10s, Trivy File ~5s, Docker Build ~20-30s, Trivy Image ~5-10s
- **Optimization strategies**:
  1. Docker layer caching (Jenkins workspace persistence)
  2. SonarQube incremental analysis (only changed files)
  3. Trivy cache mode (reuse vulnerability DB)
  4. Parallel Buildx operations

**Repo References:**
- Frontend pipeline: `three-tier-fe/Jenkinsfile`
- Backend pipeline: `three-tier-be/Jenkinsfile`
- SonarQube config: `three-tier-be/sonar-project.properties`
- Documentation: `docs/GETTING-STARTED.md` Section 7, `docs/DOCUMENTATION.md` Section 9

**Follow-up Q2.1a:** Why doesn't Jenkins update Kubernetes manifests directly?

**Answer:**
**GitOps purity principle**: Kubernetes manifests are the **single source of truth** in Git, not in Jenkins. This separation provides:

1. **Drift prevention**: ArgoCD continuously reconciles cluster state to Git; Jenkins writes would bypass this
2. **Declarative deployments**: Manifest changes are versioned, reviewed via PR, auditable
3. **Rollback simplicity**: Revert Git commit or ArgoCD sync to previous revision (no Jenkins job archaeology)
4. **Blast radius reduction**: Jenkins credential compromise doesn't grant cluster write access
5. **Improved observability**: ArgoCD UI shows deployment history, sync status, health - Jenkins can't provide this

**Instead**: Jenkins publishes artifacts (Docker images) to ECR; ArgoCD Image Updater detects new tags and updates manifests automatically or via PR.

**Follow-up Q2.1b:** How do you handle rollbacks if a bad image gets deployed?

**Answer:**
**Multi-layered rollback strategies:**

1. **Immediate rollback (Kubernetes native)**:
   ```bash
   kubectl rollout undo deployment/backend-deployment -n three-tier
   ```
   - Reverts to previous ReplicaSet (N-1 image)
   - Fast (~30s), no code changes required

2. **ArgoCD-based rollback**:
   - ArgoCD UI: Navigate to app → History → Sync to previous revision
   - CLI: `argocd app rollback backend-app <revision-id>`
   - Ensures Git state alignment (recommended approach)

3. **Tag-based rollback**:
   - ECR retains all previous images (e.g., `20241127-003`)
   - Manually update Deployment manifest to pin previous tag
   - Disable ArgoCD auto-sync temporarily to prevent Image Updater overriding

4. **Automated rollback (production enhancement)**:
   - Integrate with **Argo Rollouts** for progressive delivery
   - Define analysis templates (Prometheus metrics: error rate, latency p95)
   - Automatic rollback on failed analysis (e.g., 5xx rate > 5% for 2 minutes)

**Prevention strategies:**
- **Pre-production testing**: Deploy to staging environment first, run smoke tests
- **Canary deployments**: Route 10% traffic to new version, monitor metrics, promote gradually
- **Manual approval gate**: Add ArgoCD sync policy with `Manual: true` for production

**Follow-up Q2.1c:** How would you optimize pipeline runtime for larger applications?

**Answer:**
**Performance optimization strategies:**

1. **Parallel stage execution**:
   ```groovy
   parallel {
     stage('SonarQube') { ... }
     stage('Trivy Filesystem') { ... }
   }
   ```
   - Run independent stages concurrently (saves ~10-15s)

2. **Docker layer caching**:
   - Use `--cache-from` with ECR cache repository
   - Jenkins: Mount Docker socket, enable workspace caching
   - BuildKit: `BUILDKIT_INLINE_CACHE=1` for registry-based caching

3. **Incremental SonarQube analysis**:
   - Configure `sonar.pullrequest.provider=GitHub`
   - Analyze only changed files in PRs (vs full scan on master)

4. **Trivy caching**:
   - Mount shared Trivy cache volume (`/var/lib/trivy`)
   - Updates vulnerability DB once daily instead of per scan

5. **Build matrix optimization**:
   - For multi-platform images (amd64/arm64), use Buildx with GitHub Actions cache
   - Jenkins: Offload heavy builds to ephemeral agents (Kubernetes Jenkins agents)

6. **Artifact repository**:
   - Cache `node_modules` in Artifactory/Nexus
   - Docker stage: `COPY package*.json → RUN npm ci → COPY .`

**Expected improvements**: 30-50s → 15-25s for small apps; 5-10min → 2-4min for monoliths.

---

## 3) GitOps with ArgoCD & Image Updater

### Q3.1: Explain how ArgoCD Image Updater automatically deploys new images from ECR.

**Concise Answer:**
- **Image Updater** polls ECR every 2 minutes for new tags matching regex `^[0-9-]+$`
- Detects latest date-based tag (e.g., `20241128-002` > `20241128-001`)
- Updates Kubernetes Deployment manifest with new image tag
- ArgoCD detects manifest change, syncs to cluster with rolling update
- **No CI/CD tool** (Jenkins) touches Kubernetes manifests directly

**Deep Dive Explanation:**

**ArgoCD Image Updater Architecture:**
ArgoCD Image Updater runs as a sidecar/separate deployment in the ArgoCD namespace, watching configured applications for image update policies.

**Configuration Flow:**

1. **Application Annotations** (`argocd-apps/backend-app.yaml`):
```yaml
metadata:
  annotations:
    argocd-image-updater.argoproj.io/image-list: backend=123456789012.dkr.ecr.us-east-1.amazonaws.com/backend
    argocd-image-updater.argoproj.io/backend.allow-tags: regexp:^[0-9-]+$
    argocd-image-updater.argoproj.io/backend.update-strategy: latest
    argocd-image-updater.argoproj.io/backend.sort-tags: latest-first
```

**Annotation breakdown:**
- `image-list`: Maps app container name to ECR repository URL
- `allow-tags`: Regex filter - only considers tags matching date format (ignores `dev`, `test`, `latest`)
- `update-strategy: latest`: Always deploy the newest matching tag (alternatives: `digest`, `semver`)
- `sort-tags: latest-first`: Chronological ordering (newest tag = highest value)

2. **ECR Registry Configuration** (`argocd-image-updater-config/registries-configmap.yaml`):
```yaml
registries:
  - name: ECR
    api_url: https://123456789012.dkr.ecr.us-east-1.amazonaws.com
    prefix: 123456789012.dkr.ecr.us-east-1.amazonaws.com
    credentials: ext:/scripts/ecr-credentials-helper.sh
    credsexpire: 8h
```

**How ECR authentication works:**
- `ecr-credentials-helper.sh` script runs `aws ecr get-login-password`
- Uses **IRSA (IAM Roles for Service Accounts)** - Image Updater service account has IAM role with `ecr:GetAuthorizationToken`, `ecr:DescribeImages`, `ecr:BatchGetImage` permissions
- Credentials auto-refresh every 8 hours (ECR tokens expire after 12h)

3. **Polling & Detection Mechanism**:
   - Image Updater polls ECR every 2 minutes (configurable via `--interval` flag)
   - Fetches all tags from repository, applies regex filter
   - Compares currently deployed tag vs latest available tag
   - If newer tag exists → triggers update

4. **Manifest Update Methods** (write-back strategies):

   **Option A: In-cluster update (current implementation)**
   - Image Updater directly patches Deployment spec in cluster
   - ArgoCD marks app as "OutOfSync" but auto-sync re-applies desired state
   - **Pro**: Fast, no Git writes
   - **Con**: Git manifest becomes stale (cluster is ahead of Git)

   **Option B: Git write-back (production recommended)**
   ```yaml
   argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/git-creds
   argocd-image-updater.argoproj.io/write-back-target: "manifests/deployment.yaml"
   ```
   - Image Updater commits updated manifest to Git repository
   - Creates PR or pushes directly (depending on branch protection)
   - ArgoCD syncs from Git as usual
   - **Pro**: Git remains source of truth, audit trail
   - **Con**: Requires Git credentials, slower

5. **ArgoCD Sync Flow**:
   - ArgoCD Application configured with `syncPolicy.automated.prune: true` and `syncPolicy.automated.selfHeal: true`
   - Detects manifest change (new image tag)
   - Performs rolling update: Creates new ReplicaSet, scales up new pods, scales down old pods
   - Health checks validate new pods (readiness probes must pass)
   - Old ReplicaSet retained for rollback (controlled by `revisionHistoryLimit: 10`)

**Image Tag Versioning Strategy:**

**Why date-based tags (`YYYYMMDD-BUILD`) work perfectly with Image Updater:**
- **Lexicographic sorting**: `20241128-002` > `20241128-001` (natural ordering)
- **Human-readable**: Engineers can instantly identify image build date
- **Regex compatible**: Simple pattern `^[0-9-]+$` prevents accidental deploys of `dev`, `feature-x`, or `latest` tags
- **Traceability**: Maps directly to Jenkins build numbers and Git commits (embedded in build metadata)

**Alternative tagging strategies:**
- **Git SHAs**: `abc123def` - immutable but less readable
- **Semantic versions**: `v1.2.3` - requires manual bump logic, better for libraries
- **Hybrid**: `20241128-001-abc123d` - combines date, build number, and commit SHA

**Repo References:**
- ArgoCD apps: `argocd-apps/backend-app.yaml`, `argocd-apps/frontend-app.yaml`
- Image Updater config: `argocd-image-updater-config/registries-configmap.yaml`
- ECR credentials: `argocd-image-updater-config/ecr-credentials-helper.yaml`
- IRSA setup: `argocd-image-updater-config/bootstrap-irsa.sh`
- Documentation: `docs/DOCUMENTATION.md` Section 8

**Follow-up Q3.1a:** How do you prevent deploying bad images (e.g., failed tests but still pushed to ECR)?

**Answer:**
**Multi-layered quality gates:**

1. **Jenkins pipeline gates (preventative)**:
   - SonarQube Quality Gate: Blocks pipeline if code quality < threshold
   - Trivy scans with `--exit-code 1`: Blocks on HIGH/CRITICAL vulnerabilities
   - **Best practice**: Never push images that fail quality checks

2. **Image Updater tag filtering (defensive)**:
   - Regex `^[0-9-]+$` only allows production-ready tags
   - Tag convention: Only tag with date format *after* all checks pass
   - Development/testing images use different tags: `dev-abc123`, `test-20241128`

3. **ArgoCD health checks (reactive)**:
   ```yaml
   syncPolicy:
     automated:
       prune: true
       selfHeal: true
     syncOptions:
       - CreateNamespace=true
     retry:
       limit: 5
       backoff:
         duration: 5s
         factor: 2
         maxDuration: 3m
   ```
   - If new image causes pod failures, ArgoCD retries with backoff
   - Health assessment includes readiness/liveness probes
   - Can configure `ignoreDifferences` to prevent partial syncs

4. **Progressive delivery (production enhancement)**:
   - Use **Argo Rollouts** instead of standard Deployments
   - Define analysis templates with Prometheus queries:
     ```yaml
     metrics:
       - name: error-rate
         successCondition: result < 0.05  # 5% error rate threshold
         provider:
           prometheus:
             query: |
               sum(rate(http_requests_total{status=~"5.."}[5m]))
               /
               sum(rate(http_requests_total[5m]))
     ```
   - Automatic rollback if metrics degrade

5. **Manual approval gate (critical environments)**:
   ```yaml
   syncPolicy:
     automated: null  # Disable auto-sync
   ```
   - Require manual `argocd app sync` or UI approval for production
   - Combine with Image Updater creating Git PRs (not direct updates)

**Follow-up Q3.1b:** What happens if ECR credentials expire or Image Updater loses access?

**Answer:**
**Failure modes and recovery:**

1. **Credential expiration**:
   - ECR tokens expire after 12 hours
   - `ecr-credentials-helper.sh` configured with `credsexpire: 8h` - refreshes proactively
   - IRSA role ensures helper script can always fetch new tokens (no hardcoded credentials)

2. **If helper script fails**:
   - Image Updater logs authentication errors: `failed to get credentials for registry`
   - Applications continue running existing images (no disruption)
   - New images won't deploy until access restored
   - **Monitoring**: Set up alerts on Image Updater pod logs for `error` keyword

3. **IRSA role misconfiguration**:
   - Symptoms: `AccessDenied` errors in logs
   - Diagnosis: Check IAM policy attached to Image Updater service account
   - Required permissions:
     ```json
     {
       "Effect": "Allow",
       "Action": [
         "ecr:GetAuthorizationToken",
         "ecr:BatchCheckLayerAvailability",
         "ecr:GetDownloadUrlForLayer",
         "ecr:DescribeRepositories",
         "ecr:ListImages",
         "ecr:DescribeImages",
         "ecr:BatchGetImage"
       ],
       "Resource": "*"
     }
     ```
   - Fix: Update IAM policy, restart Image Updater pod

4. **Network connectivity issues**:
   - If Image Updater pod can't reach ECR API (VPC/firewall issues)
   - Check security groups, VPC endpoints, NAT gateway
   - Test with `kubectl exec` into Image Updater pod: `curl https://api.ecr.us-east-1.amazonaws.com`

5. **Fallback strategy**:
   - Image Updater failures don't affect running apps (graceful degradation)
   - Manual deployment option: Update manifest in Git, let ArgoCD sync
   - Emergency: `kubectl set image deployment/backend-deployment backend=<new-image>`

**Follow-up Q3.1c:** How do you audit which images were deployed and when?

**Answer:**
**Audit trail sources:**

1. **ArgoCD Application History**:
   - UI: Application → Sync Status → History tab
   - Shows all syncs with timestamp, user/automation, Git commit
   - CLI: `argocd app history backend-app`

2. **Kubernetes Events**:
   ```bash
   kubectl get events -n three-tier --sort-by='.lastTimestamp' | grep backend-deployment
   ```
   - Shows ReplicaSet creations, pod scaling, image pulls
   - Retention: 1 hour default (extend with event exporter to Elasticsearch)

3. **Git commit history** (if using write-back method):
   ```bash
   git log -- three-tier-be/manifests/deployment.yaml
   ```
   - Shows Image Updater commits with new image tags
   - Includes date, committer (argocd-image-updater bot), message

4. **ECR Image Scanning Reports**:
   - ECR console → Repository → Image tags → Scan findings
   - Maps image tag to vulnerabilities found (audit compliance)

5. **Prometheus metrics** (production enhancement):
   - Scrape ArgoCD metrics: `argocd_app_sync_total`, `argocd_app_info{image=...}`
   - Create Grafana dashboard showing deployment timeline with image tags
   - Correlate with application metrics (latency, error rate) to identify problematic releases

6. **Centralized logging** (production):
   - Export ArgoCD and Image Updater logs to Elasticsearch/CloudWatch
   - Query: `source:argocd-image-updater AND "updated image" | parse "image: *" as image_tag`
   - Retention: 90 days for compliance

---

## 4) Kubernetes & EKS

### Q4.1: Explain how the EKS cluster is provisioned and why eksctl was chosen over Terraform.

**Concise Answer:**
- **Cluster creation**: `eksctl` (CloudFormation-backed) with declarative YAML config
- **Node groups**: Managed node groups with auto-scaling (t3.medium instances)
- **Surrounding infrastructure**: Terraform (VPC, Jenkins EC2, ECR, IAM)
- **Why eksctl**: Speed, simplicity, AWS best-practice defaults, fast iteration for demos
- **Trade-off**: Split infrastructure state (eksctl CloudFormation + Terraform state)

**Deep Dive Explanation:**

**eksctl vs Terraform Decision Matrix:**

| Aspect | eksctl | Terraform |
|--------|--------|-----------|
| **Provisioning speed** | ✅ Fast (~10-15 min) | ⚠️ Slower (~15-25 min) |
| **AWS defaults** | ✅ Best practices baked in | ⚠️ Must configure manually |
| **State management** | ❌ CloudFormation stacks | ✅ Unified state file |
| **Drift detection** | ❌ Limited | ✅ `terraform plan` |
| **Learning curve** | ✅ Simple | ⚠️ Steeper |
| **GitOps integration** | ✅ Native with Flux/ArgoCD | ✅ Via modules |
| **Day-2 operations** | ⚠️ Requires AWS CLI | ✅ `terraform apply` |

**Why eksctl was chosen for this project:**
1. **Rapid prototyping**: Demo environment prioritizes speed over state unification
2. **AWS integration**: Automatic IAM OIDC provider, managed node groups, VPC CNI configuration
3. **Declarative config**: `cluster.yaml` defines everything (no imperative commands)
4. **CloudFormation benefits**: Native AWS change sets, rollback capabilities, stack policies

**eksctl cluster configuration (conceptual)**:
```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: three-tier-cluster
  region: us-east-1
  version: "1.28"

vpc:
  id: <VPC-ID-from-Terraform>  # Existing VPC
  subnets:
    public:
      us-east-1a: { id: <subnet-id> }
      us-east-1b: { id: <subnet-id> }

managedNodeGroups:
  - name: three-tier-nodes
    instanceType: t3.medium
    desiredCapacity: 2
    minSize: 1
    maxSize: 4
    volumeSize: 20
    ssh:
      allow: false  # SSM Session Manager instead
    iam:
      withAddonPolicies:
        autoScaler: true
        ebs: true
        efs: true
        albIngress: true

iam:
  withOIDC: true  # Enables IRSA for ArgoCD, ALB Controller, etc.
```

**Namespace Architecture:**

This project uses **namespace-based logical separation**:

1. **`three-tier` namespace**: Application workloads (frontend, backend, MongoDB)
   - Purpose: Isolate application components from platform services
   - RBAC: Developers get read-only access, ArgoCD has write access
   - Resource quotas: CPU 4 cores, Memory 8Gi (prevents resource exhaustion)

2. **`monitoring` namespace**: Prometheus, Grafana, Alertmanager
   - Purpose: Observability stack isolation (separate lifecycle)
   - Resource quotas: CPU 2 cores, Memory 4Gi
   - Storage: PVCs for persistent metrics and dashboards

3. **`argocd` namespace**: ArgoCD server, controllers, Image Updater
   - Purpose: GitOps control plane (privileged operations)
   - RBAC: Cluster-admin permissions (manages all namespaces)
   - Network policies: Restrict ingress to only necessary services

4. **`kube-system` namespace**: AWS Load Balancer Controller, CoreDNS, kube-proxy
   - Purpose: Critical cluster add-ons (AWS-managed and self-managed)

**Service Discovery & Networking:**

- **Within namespace**: `http://backend-service:8080/api/tasks`
- **Cross-namespace**: `http://prometheus-server.monitoring.svc.cluster.local:9090`
- **DNS**: CoreDNS resolves `<service>.<namespace>.svc.cluster.local`
- **Service types**:
  - `ClusterIP`: Backend, frontend, MongoDB (internal only)
  - `LoadBalancer`: None (ALB Ingress handles external access)

**Health Checks Configuration:**

Backend deployment example:
```yaml
spec:
  containers:
    - name: backend
      image: <ECR-backend>:latest
      ports:
        - containerPort: 8080
      livenessProbe:
        httpGet:
          path: /healthz
          port: 8080
        initialDelaySeconds: 30
        periodSeconds: 10
        failureThreshold: 3
      readinessProbe:
        httpGet:
          path: /ready
          port: 8080
        initialDelaySeconds: 10
        periodSeconds: 5
        successThreshold: 1
```

**Health check differences:**
- **Liveness**: Determines if pod should be restarted (app crash, deadlock)
- **Readiness**: Determines if pod should receive traffic (startup delays, temporary unavailability)
- **Startup** (optional): Gives slow-starting apps more time before liveness checks

**Repo References:**
- eksctl commands: `docs/GETTING-STARTED.md` Section 5
- Application manifests: `three-tier-be/manifests/deployment.yaml`, `three-tier-fe/manifests/deployment.yaml`
- Monitoring setup: `k8s-infrastructure/monitoring/`
- Namespace configs: `k8s-infrastructure/namespace.yaml`

**Follow-up Q4.1a:** Would you migrate from eksctl to Terraform for production, and why?

**Answer:**
**Yes, for production environments**. Migration provides:

1. **Unified state management**:
   - Single source of truth (`terraform.tfstate`)
   - Drift detection via `terraform plan`
   - Atomic changes (cluster + apps updated together)

2. **Better compliance & governance**:
   - Terraform Cloud/Enterprise for policy-as-code (Sentinel)
   - Cost estimation before apply
   - Audit logs for all infrastructure changes

3. **Disaster recovery**:
   - Recreate entire environment from code
   - Version-controlled infrastructure
   - Blue/green cluster deployments (two Terraform workspaces)

4. **Advanced networking**:
   - Custom VPC CNI configuration
   - Private cluster endpoints
   - VPC peering, Transit Gateway integration

**Migration approach:**
```bash
# Import existing EKS cluster to Terraform
terraform import aws_eks_cluster.main three-tier-cluster
terraform import aws_eks_node_group.main three-tier-cluster:three-tier-nodes

# Refactor eksctl resources to Terraform modules
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"
  
  cluster_name    = "three-tier-cluster"
  cluster_version = "1.28"
  
  # ... remaining config
}
```

**Trade-offs:**
- **Increased complexity**: More Terraform code to maintain
- **Learning curve**: Team needs Terraform EKS expertise
- **Migration risk**: Potential service disruption during import
- **Time investment**: 2-3 weeks for migration + testing

**When to stick with eksctl**:
- Small teams (<5 engineers)
- Rapid prototyping / demo environments
- Short-lived clusters
- AWS-centric infrastructure (no multi-cloud)

**Follow-up Q4.1b:** How do you implement resource quotas and limit ranges to prevent resource exhaustion?

**Answer:**
**Resource management strategy:**

1. **Namespace-level resource quotas** (`three-tier/resourcequota.yaml`):
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: three-tier-quota
  namespace: three-tier
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    persistentvolumeclaims: "10"
    services.loadbalancers: "0"  # Force ALB Ingress usage
    pods: "50"
```

**Effects:**
- Prevents namespace from consuming entire cluster capacity
- Forces developers to specify resource requests/limits (quota won't allow pods without them)
- Blocks accidental LoadBalancer services (cost control)

2. **LimitRange** (default per-container limits):
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: three-tier-limits
  namespace: three-tier
spec:
  limits:
    - max:
        cpu: "2"
        memory: 4Gi
      min:
        cpu: "100m"
        memory: 128Mi
      default:
        cpu: "500m"
        memory: 512Mi
      defaultRequest:
        cpu: "250m"
        memory: 256Mi
      type: Container
```

**Benefits:**
- Pods without explicit limits get sensible defaults
- Prevents accidental "unbounded" containers
- Enforces minimum resource guarantees

3. **Pod-level resource configuration** (best practice):
```yaml
spec:
  containers:
    - name: backend
      resources:
        requests:
          cpu: "250m"
          memory: "256Mi"
        limits:
          cpu: "1"
          memory: "1Gi"
```

**Resource sizing guidelines:**
- **Requests**: Guaranteed resources (used for scheduling decisions)
- **Limits**: Maximum allowed (hard cap, OOMKilled if exceeded)
- **Ratio**: Limits should be 2-4x requests (allows bursting)

4. **Monitoring resource usage**:
```bash
# Check namespace resource consumption
kubectl top nodes
kubectl top pods -n three-tier

# View resource quota utilization
kubectl describe resourcequota three-tier-quota -n three-tier
```

**Production enhancements:**
- **Vertical Pod Autoscaler (VPA)**: Automatically adjusts requests/limits based on usage
- **Horizontal Pod Autoscaler (HPA)**: Scales replicas based on CPU/memory metrics
- **PodDisruptionBudgets**: Ensures minimum availability during node drains
- **Priority classes**: Critical pods (database) get higher scheduling priority

**Follow-up Q4.1c:** How do you handle EKS cluster upgrades without downtime?

**Answer:**
**Zero-downtime upgrade strategy:**

1. **Control plane upgrade** (eksctl):
```bash
eksctl upgrade cluster --name=three-tier-cluster --version=1.29 --approve
```
- AWS performs rolling upgrade of control plane nodes
- API server remains available (multi-AZ control plane)
- Takes ~20-30 minutes
- Applications continue running (data plane unaffected)

2. **Node group upgrade strategies**:

**Option A: Managed node group update (simplest)**:
```bash
eksctl upgrade nodegroup \
  --name=three-tier-nodes \
  --cluster=three-tier-cluster \
  --kubernetes-version=1.29
```
- AWS drains and replaces nodes one by one
- Respects PodDisruptionBudgets
- Automatic rollback on failure

**Option B: Blue/green node group (zero-downtime)**:
```bash
# 1. Create new node group with v1.29
eksctl create nodegroup \
  --cluster=three-tier-cluster \
  --name=three-tier-nodes-v129 \
  --version=1.29

# 2. Migrate workloads (use taints/tolerations to control)
kubectl cordon <old-nodes>
kubectl drain <old-nodes> --ignore-daemonsets --delete-emptydir-data

# 3. Delete old node group after validation
eksctl delete nodegroup --cluster=three-tier-cluster --name=three-tier-nodes
```

**Pre-upgrade checklist:**
- ✅ Review Kubernetes deprecation warnings: `kubectl get --raw /metrics | grep deprecated`
- ✅ Test ArgoCD, ALB Controller, Prometheus compatibility with new K8s version
- ✅ Backup etcd (control plane state): `aws eks describe-cluster` → backup automation
- ✅ Verify PodDisruptionBudgets configured for critical services
- ✅ Set up rollback plan (keep old node group for 24h)

**Post-upgrade validation:**
```bash
# Check node versions
kubectl get nodes -o custom-columns=NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion

# Verify pod health
kubectl get pods --all-namespaces | grep -v Running

# Test application endpoints
curl https://todo.tarang.cloud/api/tasks
```

---

## 5) DNS & Certificates

- **Question:** How are domains and TLS managed?
- **Answer (Concise):** Hostinger manages DNS for `tarang.cloud` with CNAMEs to ALB DNS; TLS via ACM certificate referenced in Ingress annotations.
- **Deeper Explanation:**
-  - Startup script now prints steps to update Hostinger records post-recreation. ACM cert is regional (us-east-1) and attached via annotation.
- **Repo References:** `k8s-infrastructure/ingress.yaml` (cert ARN), `scripts/startup-cluster.sh` Step 10.5, `docs/SHUTDOWN-STARTUP-TESTING.md`.
- **Follow-up:** Can we automate Hostinger DNS updates?
  - If Hostinger API/CLI supports CNAME updates, we can integrate a script; currently documented as manual due to provider constraints.

---

## 6) Infrastructure Provisioning & Teardown

- **Question:** What provisions infra, and how do you tear it down?
- **Answer (Concise):** Terraform provisions Jenkins EC2/VPC/ECR/IAM; eksctl creates EKS. Teardown order: delete K8s apps → delete EKS (eksctl) → `terraform destroy`.
- **Deeper Explanation:**
  - Order avoids dependency issues (ALB/ENIs/SGs). Terraform is the PRIMARY destruction method for its resources and includes troubleshooting for ENIs, SGs, EIPs, ECR non-empty repos.
- **Repo References:** `Jenkins-Server-TF/*.tf`, `docs/GETTING-STARTED.md` Infrastructure Cleanup section.
- **Follow-up:** Why not create EKS with Terraform?
  - Chosen for simplicity with eksctl (CloudFormation-backed, fast). Could migrate to Terraform to centralize infra state, but adds complexity.

---

## 7) Security & Compliance

- **Question:** What security controls are implemented in CI/CD?
- **Answer (Concise):** SonarQube quality gate, Trivy filesystem and image scans, minimal IAM permissions, private ECR, ALB HTTPS.
- **Deeper Explanation:**
  - Nodegroup and pods use least-privilege; ECR scanning-on-push; restrict SG ingress to required ports; TLS enforced via SSL-redirect; secrets managed in `k8s-infrastructure/Database/secrets.yaml` (consider external secret manager for production).
- **Repo References:** `Jenkins-Server-TF/ecr_repositories.tf`, security groups in `Jenkins-Server-TF/vpc.tf`, Jenkins pipeline stages.
- **Follow-up:** How would you add SAST/DAST and secret scanning?
  - Add Snyk/GitHub Advanced Security (CodeQL), OWASP ZAP in pipeline, TruffleHog/Gitleaks for secrets. Gate merges on findings.

---

## 8) Observability (Prometheus & Grafana)

- **Question:** How are metrics collected and visualized?
- **Answer (Concise):** Prometheus scrapes app and cluster metrics; Grafana dashboards visualize. Both persist via PVCs and are exposed via shared ALB.
- **Deeper Explanation:**
  - Prometheus values configure targets, retention, persistent storage (20Gi); Grafana stores dashboards (10Gi). Datasource configured to Prometheus service. Access via `monitoring.tarang.cloud` paths.
- **Repo References:** `k8s-infrastructure/monitoring/prometheus-values.yaml`, `docs/MONITORING-INGRESS-DEPLOYMENT.md`.
- **Follow-up:** How to add alerting?
  - Add Alertmanager with SMTP/Slack; configure Prometheus alert rules for pod restarts, high latency, error rates, disk usage.

---

## 9) Reliability & Operations

- **Question:** How do you ensure zero-downtime deployments?
- **Answer (Concise):** Rolling updates via Kubernetes, image tag updates are applied by ArgoCD with health checks; ALB routes traffic continuously.
- **Deeper Explanation:**
  - Proper readiness/liveness probes, resource requests/limits, and replicas maintain availability. Jenkins and ArgoCD separation avoids deployment delays.
- **Repo References:** `three-tier-be/manifests/deployment.yaml`, `three-tier-fe/manifests/deployment.yaml`.
- **Follow-up:** What’s your rollback strategy?
  - ArgoCD supports app rollback to previous revision/tag; ECR stores previous images; can pin tag or revert commit.

---

## 10) Cost Management

- **Question:** What are the main cost drivers and optimizations?
- **Answer (Concise):** EC2 (Jenkins), EKS (control plane + nodes), ALB, ECR storage, EBS volumes.
- **Deeper Explanation:**
  - Optimizations: shared ALB, right-size instances, lifecycle policies for ECR, shut down environments when idle, periodic teardown. Monitor via AWS Cost Explorer.
- **Repo References:** `docs/AWS-COST-MANAGEMENT.md`, `docs/GETTING-STARTED.md` notes.
- **Follow-up:** How to reduce ALB costs further?
  - Consolidate services, consider API Gateway + NLB in certain cases, or staging-only exposure via port-forwarding when acceptable.

---

## 11) Data & Persistence

- **Question:** Which components use persistent storage and what survives cluster recreation?
- **Answer (Concise):** Jenkins EBS, MongoDB PVC, Prometheus (20Gi), Grafana (10Gi) persist. ALB DNS, node IPs, instance IDs change.
- **Deeper Explanation:**
  - PVCs bound to storage class (EBS). On recreation, volumes can be reattached or reclaimed depending on reclaim policy and manifests.
- **Repo References:** `k8s-infrastructure/Database/pv.yaml`, `pvc.yaml`, monitoring PVCs.
- **Follow-up:** How do you backup/restore?
  - Snapshot EBS, export Grafana dashboards, backup MongoDB via `mongodump`, store in S3, define restore playbooks.

---

## 12) Networking & Security Groups

- **Question:** Explain VPC and security group setup for Jenkins.
- **Answer (Concise):** Single VPC `10.0.0.0/16`, public subnet `10.0.1.0/24`, IGW, route table `0.0.0.0/0`, SG allows 22/80/443/8080/9000 inbound; all outbound enabled.
- **Deeper Explanation:**
  - Simplicity for demo; production would restrict CIDRs, add WAF, bastion/SSM, private subnets with NAT, split SGs per role.
- **Repo References:** `Jenkins-Server-TF/vpc.tf`.
- **Follow-up:** How would you harden this for production?
  - Use SSM Session Manager (no SSH), restrict ingress CIDRs, least-privileged IAM, mutual TLS, WAF, private EKS with endpoint access controls.

---

## 13) Risks & Improvements

- **Question:** What are key risks and how would you mitigate?
- **Answer (Concise):** DNS ALB changes (manual update), single Jenkins, limited secrets management, public SGs.
- **Deeper Explanation:**
  - Mitigations: Automate Hostinger updates if possible; HA Jenkins or managed CI; external secret manager (AWS Secrets Manager/HashiCorp Vault); lock down SGs; IaC unification.
- **Repo References:** `scripts/startup-cluster.sh`, `docs/SHUTDOWN-STARTUP-TESTING.md`, Terraform modules.
- **Follow-up:** Would you migrate eksctl → Terraform?
  - Yes, for unified state, plan/apply consistency, and drift detection. Evaluate trade-offs vs eksctl speed/convenience.

---

## 14) Troubleshooting & Incident Response

- **Question:** Common issues and fixes?
- **Answer (Concise):**
  - Pods Pending → check node capacity/resource requests.
  - ALB not healthy → verify `/healthz` path, SG rules, target type.
  - ArgoCD OutOfSync → Sync; check Image Updater creds.
  - Jenkins ECR push fails → IAM/ECR auth.
- **Repo References:** `docs/GETTING-STARTED.md` Troubleshooting; `docs/DOCUMENTATION.md` Section 15.
- **Follow-up:** How to quickly diagnose cluster access issues?
  - `aws eks update-kubeconfig`, check `~/.kube/config`, role permissions, cluster endpoint reachability.

---

## 15) Teardown & Recovery

- **Question:** Explain the teardown plan and rationale.
- **Answer (Concise):** Delete K8s apps (ALB cleanup) → delete EKS (eksctl) → **terraform destroy** (PRIMARY) → verify costs/resources → DNS updates.
- **Deeper Explanation:**
  - Prevents orphaned ENIs/EIPs/ALBs. Documented commands and automation script included in `GETTING-STARTED.md`. Manual verification ensures no lingering charges.
- **Repo References:** `docs/GETTING-STARTED.md` Infrastructure Cleanup section.
- **Follow-up:** What if Terraform destroy fails repeatedly?
  - Diagnose dependencies (ENIs/SGs/EIPs); use targeted destroy, then state operations cautiously; ensure resources actually deleted before state edits.

---

## 16) Leadership & Real-World Readiness

- **Question:** How would you scale this for a product company?
- **Answer (Concise):**
  - Multi-env (dev/stage/prod) with separate namespaces/accounts, centralized secrets management, progressive delivery (Argo Rollouts), observability with SLOs, infra unification, and cost budgets.
- **Deeper Explanation:**
  - Add infra modules, CI/CD hardening, dependency scanning, SBOMs, policy-as-code (OPA/Gatekeeper), blue/green or canary deployments, disaster recovery runbooks.
- **Follow-up:** How do you ensure team adoption?
  - Clear docs, golden paths, self-service tooling, guardrails, automated checks in PRs, and dashboards for visibility.

---

## Appendix: Fast References
- Ingress config: `k8s-infrastructure/ingress.yaml`
- Monitoring ingress: `k8s-infrastructure/monitoring/monitoring-ingress.yaml`
- ArgoCD apps: `argocd-apps/*.yaml`
- Image Updater config: `argocd-image-updater-config/*`
- Terraform infra: `Jenkins-Server-TF/*.tf`
- Teardown guide: `docs/GETTING-STARTED.md`
- DNS note: `scripts/startup-cluster.sh`, `docs/SHUTDOWN-STARTUP-TESTING.md`
# Senior DevOps Interview Q&A — Curated (Three-Tier DevSecOps on AWS EKS)

Purpose: Focused, project-centric Senior DevOps / DevOps Lead interview preparation. Each section contains high‑value decision rationale, concise answers, and senior‑level follow‑ups tied directly to this repository. Bloated or redundant narrative blocks from the previous version have been removed.

Sections
1. Architecture & Core Design
2. CI/CD Pipeline & Image Strategy
3. GitOps (ArgoCD + Image Updater)
4. Kubernetes / EKS Provisioning & Namespace Model
5. Services, Ingress & Traffic Management
6. Scaling & Resilience (HPA, VPA, Upgrades, PDB)
7. Observability & Alerting
8. Security & Compliance
9. Infrastructure as Code & Lifecycle (Terraform vs eksctl)
10. Data Persistence & Backup/Restore
11. Cost Optimization
12. Operational Runbook (Startup / Shutdown / DNS / Certs)
13. Troubleshooting & Incident Response Playbook
14. Progressive Delivery & Multi‑Environment Evolution
15. Leadership & Enablement
16. Quick Reference Cheat Sheet

---

## 1. Architecture & Core Design

Q1: Summarize the architecture.
Answer: Three logical repos: infra/control-plane (Terraform, manifests, ArgoCD, monitoring), `three-tier-fe` (React served by Nginx), `three-tier-be` (Node/Express + MongoDB). Jenkins builds & scans → pushes date‑tagged images to ECR. ArgoCD Image Updater detects new tags (regex `^[0-9-]+$`), updates Deployment image, ArgoCD auto-sync performs rolling update. Single ALB Ingress with path routing for app, API, metrics, dashboards.
Follow-ups:
- Why separate repos? Independent versioning, isolated pipelines (avoid cross-trigger), clearer ownership/RBAC, reduced blast radius.
- Why not monorepo? Monorepo brings atomic PR coordination but adds pipeline complexity and broader failure domains.
- Why Node + React for demo? Fast start, low container build time, easy vulnerability scanning footprint.

Q2: Key deliberate trade-offs.
Answer: Shared ALB (cost/control) vs multiple LBs; eksctl for speed vs Terraform for unified state; date tags for readability vs SHA tags for strict immutability; auto-sync for rapid iteration vs manual sync for prod gating.
Follow-ups:
- When to change each choice? Prod hardening: Terraform cluster, canary/rollouts, multi‑ALB for isolation, dual tagging (date + SHA), progressive delivery.
- Risks now? Manual DNS updates, single Jenkins host, limited secrets strategy, mixed IaC toolchain.

Q3: Persistence across cluster recreation.
Answer: PVCs (MongoDB, Prometheus 20Gi, Grafana 10Gi) + Jenkins EBS survive; ALB DNS name & node IPs change. Docs clarify expected mutable vs durable assets.
Follow-ups:
- Hardening? Scheduled EBS snapshots, remote-write for Prometheus, Grafana JSON export pipeline, automated MongoDB backups (cron + `mongodump` to S3). Define RPO/RTO.

---

## 2. CI/CD Pipeline & Image Strategy

Q1: Pipeline stages and rationale.
Answer: (1) SonarQube Analysis & Quality Gate (fail fast) (2) Trivy filesystem scan (dependencies + source) (3) Docker build & push (Buildx, deterministic tag) (4) Trivy image scan (base image CVEs). Ensures code + dependency + image hygiene before deploy. Typical duration ~30–50s due to cached layers and small codebase.
Follow-ups:
- Why two Trivy scans? Filesystem catches app/library issues before build; image scan validates final artifact layers (base + OS). Different vantage points reduce blind spots.
- Where block occurs? Any failing gate halts push so GitOps system never sees unsafe tag.

Q2: Tagging strategy.
Answer: `YYYYMMDD-BUILD` chosen for readability, chronological sort, simple regex filtering, quick human correlation with pipeline runs.
Follow-ups:
- Compare with commit SHA: SHA is immutable & reproducible; date tag is operationally transparent. Senior approach: apply both (`20241128-005_ab12cd3`).
- Avoid “latest”? Non-deterministic; breaks rollback provenance and audit trails.

Q3: Rollback patterns.
Answer: Re‑deploy prior image tag or `kubectl rollout undo`; for GitOps integrity prefer commit revert or re‑pin manifest image tag then allow ArgoCD sync.
Follow-ups:
- Faster path vs safer path? Faster = direct `kubectl set image`; safer = Git revert (captured in audit & reconciled).

---

## 3. GitOps (ArgoCD + Image Updater)

Q1: Flow from build to deploy.
Answer: Jenkins pushes → Image Updater polls ECR (credentials via IRSA helper) → tag matches policy regex → updater writes back (annotation/manifest change) → ArgoCD detects diff → rolling update.
Follow-ups:
- Why not Jenkins editing manifests? Separation of concerns; Git remains source of truth; reduces script drift & credential sprawl.
- Audit trail sources? ArgoCD app history, Git commits (if write-back), ECR scan results, deployment events.

Q2: Securing registry access.
Answer: IRSA role with minimal ECR actions (`DescribeImages`, `BatchGetImage`, `GetAuthorizationToken`). Helper rotates token ahead of expiry.
Follow-ups:
- Failure handling? If creds lapse, deployments pause (no new tags) without affecting current running pods; manual manifest edit fallback.
- Misconfiguration signals? `AccessDenied` in updater logs; absence of tag refresh; OutOfSync persists.

Q3: When to disable auto-sync.
Answer: Production gating, controlled canaries, regulatory change controls.
Follow-ups:
- Pattern? Image Updater opens PR; merge approval triggers sync; policy engine (OPA/Sentinel) validates before merge.

---

## 4. Kubernetes / EKS Provisioning & Namespace Model

Q1: eksctl vs Terraform choice.
Answer: eksctl accelerates cluster bootstrap (CloudFormation stacks, sane defaults, OIDC setup) for a demo timeline. Terraform manages surrounding AWS core (VPC, ECR, EC2 Jenkins, IAM) for reproducibility.
Follow-ups:
- Migration trigger? Need unified drift detection, policy-as-code, multi‑workspace environment promotion, advanced networking.
- Risks of split? Fragmented state visibility; additional operator tooling context required.

Q2: Namespace strategy.
Answer: `three-tier` (app workloads), `monitoring` (Prometheus/Grafana), `argocd` (GitOps control), plus system namespaces. Provides blast radius control & resource governance.
Follow-ups:
- Resource governance? Quotas, LimitRanges, RBAC roles, pod security standards (future), network policies for egress scoping.

Q3: Resource management.
Answer: Requests/limits sized conservatively; quotas prevent noisy neighbor exhaustion; LimitRange enforces defaults; future: introduce VPA recommendation mode.
Follow-ups:
- Capacity visibility? `kubectl top`, Prometheus `node_exporter` & kube-state metrics; dashboards with saturation trends.

---

## 5. Services, Ingress & Traffic Management

Q1: Service types rationale.
Answer: Internal components use `ClusterIP`; external access consolidated through ALB Ingress (eliminates extra LBs). No `NodePort` exposure (security/cost).
Follow-ups:
- When to use LoadBalancer service instead? Edge cases needing direct L4, distinct scaling domain, or migration path away from shared ingress.
- NodePort pitfalls? Ephemeral node IP churn, manual port management, security surface expansion.

Q2: Ingress vs individual LoadBalancers.
Answer: Ingress consolidates TLS, routing, cost; multiple LBs increase isolation & per‑service SLAs.
Follow-ups:
- Isolation criteria? Different compliance domains, tenant separation, divergent WAF rules.

Q3: Health & readiness.
Answer: ALB targets backend probe path; readiness ensures traffic gating; liveness restarts faulty pods.
Follow-ups:
- Flapping mitigation? Increase thresholds, add startupProbe for slow init, decouple DB readiness from HTTP accept.

Q4: Sidecar patterns (not used yet).
Answer: Potential: envoy/istio for mTLS & tracing; fluentbit/logging; metrics sidecars.
Follow-ups:
- Introduce when? Need distributed tracing, policy enforcement, zero‑trust, standardized telemetry injection.

---

## 6. Scaling & Resilience

Q1: Horizontal scaling.
Answer: Introduce HPA based on CPU and custom (Prometheus Adapter) metrics once baseline load patterns observed. Initial small footprint removes premature complexity.
Follow-ups:
- Custom metrics examples? Request latency p95, queue depth, error rate.
- HPA pitfalls? Oscillation from noisy metrics; fix with stabilization windows & proper target utilization.

Q2: Vertical & cluster scaling.
Answer: VPA (recommendation or autoset) for right-sizing; Cluster Autoscaler integrated with managed node groups & appropriate instance types.
Follow-ups:
- Avoid resource thrash? Set min/max, review utilization trends, couple with quota enforcement.

Q3: Resilience primitives.
Answer: PodDisruptionBudgets prevent unsafe concurrent evictions; multi‑AZ node groups; rolling upgrades; revisionHistory for rollback.
Follow-ups:
- Upgrade zero‑downtime pattern? Blue/green node group or in‑place managed group upgrade with PDB safeguards.

---

## 7. Observability & Alerting

Q1: Metrics collection.
Answer: Prometheus scrapes cluster + application endpoints; Grafana dashboards provide latency, error, saturation, resource trends; PVCs ensure persistence.
Follow-ups:
- Production enhancements? Alertmanager with SLO burn-rate alerts; tracing (OpenTelemetry) + log aggregation; synthetic probes.

Q2: Alert philosophy.
Answer: Start with actionable high-signal alerts (availability, error spike, resource exhaustion) before exhaustive low‑value noise.
Follow-ups:
- Reduce false positives? Multi-window burn-rate, label-based silences, severity tiers.

---

## 8. Security & Compliance

Q1: Pipeline security gates.
Answer: SonarQube Quality Gate + dual Trivy scans. Failing either blocks image push → blocks GitOps deployment.
Follow-ups:
- Extend chain? Add SAST (Semgrep), secret scanning (Gitleaks), SBOM generation (Syft), admission controls (OPA/Gatekeeper).

Q2: Runtime & supply chain.
Answer: Private ECR, minimal IAM via IRSA, TLS on ingress, restrict LoadBalancer proliferation with quotas.
Follow-ups:
- Image integrity? Introduce cosign signing + policy validation.

Q3: Secrets management evolution.
Answer: Currently K8s secrets; future path: External Secrets + AWS Secrets Manager or Vault; envelope encryption + rotation.
Follow-ups:
- Rotation cadence? High‑risk (DB creds) 90d, service tokens 30d, certificate renewals automated via ACM.

---

## 9. Infrastructure as Code & Lifecycle

Q1: Split toolchain rationale.
Answer: Terraform excels at foundational AWS constructs & destroy orchestration; eksctl accelerates cluster spin‑up without authoring extensive module code.
Follow-ups:
- Migration trigger? Need unified policy, drift plan visibility, complex networking, compliance automation.

Q2: Teardown order.
Answer: 1) Delete K8s workloads (frees ALB, ENIs) 2) Delete EKS cluster (eksctl) 3) `terraform destroy` for underlying infra.
Follow-ups:
- Common failure points? Orphaned ENIs, lingering ECR images, SG dependencies; targeted cleanup then re-run.

Q3: Disaster recovery infra.
Answer: Re-provision from code + restore persistent volumes/backups; treat Terraform state as critical—store remotely & version.
Follow-ups:
- Improve RTO? Prebaked AMIs, modular Terraform with parallel apply, snapshot orchestration.

---

## 10. Data Persistence & Backup/Restore

Q1: Persistent components.
Answer: MongoDB, Prometheus, Grafana PVCs + Jenkins EBS volume.
Follow-ups:
- Backup strategy? EBS snapshots + `mongodump` + Grafana API export + remote-write for metrics.
- Restore validation? Scheduled quarterly fire-drill restore into staging.

Q2: Recreate cluster impact.
Answer: Volumes survive if not deleted; ALB & ephemeral endpoints change; DNS manual step updates CNAME.
Follow-ups:
- Risk mitigation? Automate DNS update or move to Route53; document diff checklist.

---

## 11. Cost Optimization

Q1: Primary cost levers.
Answer: ALB hourly, EKS control plane, worker nodes, EBS, ECR storage.
Follow-ups:
- Active optimizations? Shared ALB, right-sized nodes, lifecycle policy for images, teardown guidance, minimal always‑on services.
- Future? Spot node groups, autoscaled monitoring, scale-to-zero non‑prod, multi‑AZ cost balancing.

---

## 12. Operational Runbook (Startup / Shutdown / DNS / Certs)

Q1: ALB & DNS handling.
Answer: ALB hostname changes after cluster recreation; Hostinger CNAME manual update documented in startup script.
Follow-ups:
- Automate? Hostinger API or migrate DNS to Route53 for scripted record changes.

Q2: Certificate lifecycle.
Answer: ACM cert referenced via annotation; rotation is transparent once ARN updated.
Follow-ups:
- Improve? Automate expiry monitoring + pre‑rotation validation; export certificate metadata to dashboard.

Q3: What persists vs changes.
Answer: PVCs & EBS persist; dynamic infra endpoints change (ALB DNS, node IDs). Runbook enumerates verification tasks.
Follow-ups:
- Startup validation checklist? DNS updated, pods healthy, ingress rules active, monitoring dashboards reachable, no failing alerts.

---

## 13. Troubleshooting & Incident Response Playbook

Selected Scenarios (Symptom → Primary Checks → Action):
- Pods Pending → Describe pod (resources, PVC), node allocatable, quotas → Adjust requests / scale nodes / fix binding.
- ALB not healthy → Target health, `/healthz` path, SG rules, controller logs → Correct path/ports, redeploy ingress.
- ArgoCD OutOfSync → App diff, image tag regex mismatch, ECR creds → Fix credentials/regex, manual sync.
- Image Updater silent → Pod logs, IAM actions, token expiry → Renew IRSA policy or helper script, restart pod.
- Jenkins ECR push fails → IAM permissions, region mismatch, repository existence → Re-auth & verify policies.
- Node join failure → `aws-auth` ConfigMap, subnet routing, instance profile → Patch mapping or network.
- Resource quota blocks deploy → Inspect quota usage → Increase limits or optimize resource sizing.
- High latency spike → Check HPA scaling lag, saturation dashboards → Increase replicas / allocate more CPU / investigate DB.

Response Principles: Prioritize containment (stop bad rollout), observability triage (logs/metrics/events), root cause isolation (component boundaries), documented remediation, and post‑incident follow-up (add missing guardrail).

---

## 14. Progressive Delivery & Multi‑Environment Evolution

Q1: Path to multi‑env scaling.
Answer: Separate Terraform workspaces or accounts (dev/stage/prod), dedicated ArgoCD projects per env, image promotion via signed tags, environment-specific policies.
Follow-ups:
- Promotion model? Build once → scan → promote artifact tag (immutable) across envs; disallow rebuild per env.

Q2: Progressive rollout.
Answer: Introduce Argo Rollouts (canary / blue-green) with Prometheus analysis templates.
Follow-ups:
- Rollback trigger metrics? Error rate, latency degradation, saturation, custom business KPIs.

---

## 15. Leadership & Enablement

Q1: Enabling team adoption.
Answer: Golden path docs, templated Jenkins pipelines, PR governance, dashboards for reliability KPIs, guardrails instead of gates.
Follow-ups:
- Knowledge scaling? Short internal workshops, architecture decision records (ADRs), automated lint/policy feedback early in PRs.

Q2: Prioritizing improvements.
Answer: Weighted by risk (security > reliability > performance > cost), ROI, and alignment to product roadmap.
Follow-ups:
- Tracking? Observability-driven OKRs (MTTR, deploy frequency) + backlog of tech debt items.

---

## 16. Quick Reference Cheat Sheet

Image Tag Regex: `^[0-9-]+$`
Ingress Cert Annotation: `alb.ingress.kubernetes.io/certificate-arn: <ACM-ARN>`
Rollback (GitOps): Revert manifest commit or re-pin image tag → ArgoCD sync.
Pipeline Gates: SonarQube Quality Gate + Trivy (`--exit-code 1`).
Teardown Order: K8s apps → EKS cluster (eksctl) → Terraform destroy.
Namespaces: `three-tier`, `monitoring`, `argocd` (plus system).
Persistent Storage: MongoDB PVC, Prometheus 20Gi, Grafana 10Gi, Jenkins EBS.
Core Risk Items: Manual DNS, single Jenkins, mixed IaC, secrets plain K8s.
High-Value Next Steps: IRSA everywhere, progressive delivery, unified Terraform, automated DNS, backup automation.

---

Use this curated set to articulate senior-level reasoning: emphasize trade-offs, governance, reproducibility, and measured evolution rather than premature optimization.

---

## Security (SonarQube + Trivy + IAM)

- Q: What security checks are integrated in CI?
  - A: SonarQube for static analysis + Quality Gate; Trivy file scan (SCA) pre-build; Trivy image scan post-build to catch base image CVEs; pipeline fails on high severity.
  - Follow-up: Where are thresholds configured? Jenkins pipeline stages with Trivy flags and quality gate enforcement.
  - Follow-up Answer: SonarQube Quality Gate configured server-side (coverage, bugs, vulnerabilities). Trivy thresholds via CLI flags; policy-as-code can be added (e.g., OPA in CI) to enforce org-level standards.

- Q: How are AWS permissions scoped?
  - A: Terraform defines IAM roles/policies for Jenkins EC2, ECR access; `eksctl` sets up cluster IAM. Principle of least privilege for ECR push/pull, S3 state (if used), and ALB annotations.
  - Follow-up: Would you use IRSA? Yes, for in-cluster controllers needing AWS APIs (ALB controller, Image Updater to ECR).
  - Follow-up Answer: IRSA maps KSA→IAM with fine-grained policies, preventing node-level broad credentials. Apply condition keys (e.g., `aws:SourceArn`, `aws:SourceAccount`) and restrict to required actions only.

---

## Infrastructure as Code (Terraform)

- Q: What does Terraform manage vs `eksctl`/`kubectl`?
  - A: Terraform: VPC, subnets, IGW, route tables, security groups, Jenkins EC2 (with EIP), IAM roles/policies, ECR repos. `eksctl`: EKS cluster/nodegroups/CFN stacks. `kubectl`/Helm: K8s apps, ArgoCD, monitoring.
  - Follow-up: Why split ownership? Faster demos, simplified cluster ops, while keeping core infra codified.
  - Follow-up Answer: Each tool excels in its domain—Terraform for foundational AWS resources and lifecycle, `eksctl` for quick cluster setup, ArgoCD for app state. Split reduces coupling and speeds iteration while preserving IaC for reproducibility.

- Q: How do you destroy infrastructure safely?
  - A: Reverse order: delete K8s resources → `eksctl delete cluster` → `terraform destroy`. Documentation now emphasizes Terraform as the primary destruction method for Terraform-managed resources.
  - Follow-up: What common destroy failures occur? VPC dependencies (ENIs/SGs), EIP associations, non-empty ECR; fix via targeted cleanup and re-run.
  - Follow-up Answer: Diagnose with `terraform state list` and AWS CLI. Delete dangling ENIs, disassociate EIPs, purge ECR images, then retry. Avoid manual deletion of Terraform-managed resources unless you reconcile state (`terraform import` or `state rm`).

---

## Cost & Reliability

- Q: What are key cost drivers and how are they controlled?
  - A: ALB hourly costs, EC2 (Jenkins), EKS control plane, EBS for PVCs. Mitigations: shared ALB, lifecycle policies for ECR, shutdown/startup scripts, teardown guide, monitoring retained only as needed.
  - Follow-up: Further reductions? Spot nodes for worker groups, scale-to-zero for non-prod, suspend ALB when idle (by removing ingress).

- Q: How do you measure success and reliability?
  - A: Success metrics documented: automated CI/CD, GitOps stability, zero-downtime deployments, fast pipeline times (~30–50s), monitoring coverage, security scans enforced.
  - Follow-up: What SLIs/SLOs would you define? Error rate, latency, deployment frequency, MTTR, availability.

---

## Operations: Shutdown/Startup & DNS

- Q: Why does the ALB DNS change on cluster recreation and how is it handled?
  - A: ALB hostname is generated per ingress/controller instantiation; on recreation, hostname changes. DNS is managed in Hostinger; startup script and docs include manual update steps to point CNAMEs (`todo.tarang.cloud`, `monitoring.tarang.cloud`) to the new ALB DNS.
  - Follow-up: How to automate DNS? Use Hostinger API or move DNS to Route53 for automated updates.
  - Follow-up Answer: Build a small tool in the startup script to hit Hostinger’s DNS API or migrate DNS to Route53 to use `aws route53 change-resource-record-sets`. Alternatively, stabilize ingress with static NLB + separate ALB per app.

- Q: What persists vs changes after shutdown/startup?
  - A: Persists: Grafana/Prometheus/MongoDB PVCs, Jenkins EBS. Changes: ALB DNS, node IPs, instance IDs. Testing guide documents verification and recovery steps.
  - Follow-up: How to ensure zero data loss? Scheduled backups and restore workflows.
  - Follow-up Answer: Automate EBS snapshots and DB dumps; test restores quarterly; version dashboard JSON exports; store configs in Git; use `azd`/Terraform lifecycle hooks to enforce pre-shutdown backup steps.

---

## Troubleshooting & Failure Scenarios

- Q: ALB not deleting after namespace cleanup—what’s your approach?
  - A: Confirm ingress deletion; check for finalizers; remove via `finalize` API if stuck; manually delete ALB only after confirming controllers are gone to avoid drift.
  - Follow-up: How to prevent stuck finalizers? Keep controllers healthy; avoid abrupt deletions; use Helm uninstall.
  - Follow-up Answer: Ensure the ALB controller is running during deletions; avoid force-deleting namespaces; use `kubectl delete ingress` before removing controllers; monitor controller logs for reconciliation errors.

- Q: ArgoCD shows OutOfSync—what are common causes?
  - A: Image Updater tag not matching regex; ECR credentials issue; sync disabled; cluster RBAC. Fix credentials, validate regex, enable auto-sync, and check controller logs.
  - Follow-up: How to trace Image Updater decisions? Inspect its logs and annotations on deployments.
  - Follow-up Answer: Check the `argocd-image-updater` pod logs; verify `argocd-image-updater.argoproj.io/image-list` annotations; confirm tag regex in `registries-configmap.yaml`; simulate with a test tag push to ECR.

- Q: Jenkins push to ECR fails intermittently—debug steps?
  - A: Validate IAM role, ECR login, repository existence, region; inspect Docker Buildx and network; check rate limits.
  - Follow-up: Would you use retries? Yes, with backoff; capture build artifacts and logs.
  - Follow-up Answer: Implement exponential backoff for `docker push`, re-login to ECR on failure, and cap concurrency. If systemic, review SG/NACL, and enable CloudWatch metrics for ECR API calls.

- Q: EKS nodes not joining—what do you check?
  - A: Subnet routing, SG rules, IAM instance profile for node groups, AMI compatibility, kubelet versions.
  - Follow-up: How to test from inside node? SSH/SSM session; check kubelet/systemd logs.
  - Follow-up Answer: Use SSM Session Manager, inspect `/var/log/messages`, `journalctl -u kubelet`, confirm `aws-auth` ConfigMap mapping, and verify cluster endpoint reachability.

- Q: K8s pods in Pending—likely reasons?
  - A: Insufficient resources, PVC binding issues, taints/tolerations. Examine `kubectl describe pod`, node allocatable vs requests.
  - Follow-up: How to right-size? Use resource requests/limits and HPA/VPA.
  - Follow-up Answer: Measure usage with kube-state-metrics + Prometheus; set conservative requests; enable HPA on CPU/memory or custom metrics; add VPA for recommendation mode.

---

## Advanced/Design Trade-offs

- Q: If scaling to multi-environment (dev/stage/prod), what changes?
  - A: Separate clusters/namespaces, per-env ArgoCD apps, env-specific ECR repos, Terraform workspaces, per-env ALBs/ingress rules, secrets management (e.g., AWS Secrets Manager/External Secrets).
  - Follow-up: Promotion strategy? Use tags/branches, image promotion via registries, policy gates.

- Q: How would you implement progressive delivery?
  - A: Argo Rollouts/Canary/Blue-Green, metrics-driven analysis via Prometheus, automated rollback on threshold breaches.
  - Follow-up: What metrics? Error rate, p95 latency, saturation.

- Q: How would you enhance security posture?
  - A: IRSA for controllers, network policies, limit SG exposure, private subnets + NAT, image signing (cosign), admission controls (OPA/Gatekeeper), secret encryption at rest.
  - Follow-up: SBOM management? Trivy + Grype; store SBOMs; vuln monitoring.

---

## Quick Reference: Repo-Specific Facts

- Repos: infra repo + `three-tier-fe` + `three-tier-be`
- Jenkins pipelines: 4 stages; ~30–50s runtime
- Image tags: `YYYYMMDD-BUILD`; regex `^[0-9-]+$`
- ECR repos: `frontend`, `backend` (Terraform-managed)
- Ingress: `mainlb` (namespace `three-tier`), ALB annotations including ACM cert ARN
- Monitoring ingress: paths under shared ALB
- PVCs: Grafana 10Gi, Prometheus 20Gi, MongoDB PVC
- Infra split: Terraform (VPC/EC2/ECR/IAM), `eksctl` (cluster), `kubectl/Helm` (apps)
- DNS: Hostinger CNAMEs to ALB; manual update after cluster recreation
- Teardown order: K8s → `eksctl` → `terraform destroy`

---

## Final Note

Use these Q&As to demonstrate practical decision-making, clarity in trade-offs, and command over GitOps/Kubernetes on AWS. Tailor answers to product contexts by referencing this repo’s concrete implementations and documented behaviors.
