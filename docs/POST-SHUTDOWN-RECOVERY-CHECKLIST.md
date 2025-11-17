# Post-Shutdown Recovery Checklist

## Overview
When shutting down AWS infrastructure for cost savings, bringing it back up requires addressing multiple issues. This document provides a roadmap for faster recovery based on issues encountered during our Nov 17, 2025 recovery.

---

## Issues Encountered After Infrastructure Restart

### 1. **EKS Node Groups Deleted for Cost Savings**
- **Issue:** Node groups were manually deleted; had to recreate from scratch
- **Impact:** No worker nodes = no pods running, complete application downtime
- **Fix:** Created new node group (ng-960b346f-new) with 2 t2.medium instances using AWS Console
- **Recovery Time:** ~10 minutes
- **Prevention:** Document node group configuration before deletion; consider stopping nodes instead

### 2. **SonarQube Data Loss After Container Restart**
- **Issue:** SonarQube lost all data (tokens, projects, quality gates, webhooks) after Docker restart
- **Root Cause:** No persistent volumes configured; data stored in ephemeral container storage
- **Fix:** Added volume mounts: `/opt/sonarqube/data`, `/opt/sonarqube/logs`, `/opt/sonarqube/extensions`
- **Recovery Time:** ~15 minutes (reconfigure + test)
- **Prevention:** Always use persistent volumes for stateful containers

### 3. **SonarQube Authentication Tokens Expired**
- **Issue:** Jenkins couldn't authenticate with SonarQube; builds failing at quality gate stage
- **Root Cause:** Token stored in SonarQube was lost due to no persistence
- **Fix:** Regenerated SonarQube token, updated Jenkins credentials
- **Recovery Time:** ~5 minutes
- **Prevention:** Persistent volumes (implemented) + document token regeneration process

### 4. **SonarQube Webhook Not Configured**
- **Issue:** Jenkins builds hung indefinitely waiting for Quality Gate results
- **Root Cause:** Webhook configuration lost after SonarQube restart
- **Fix:** Reconfigured webhook: `http://3.227.140.48:8080/sonarqube-webhook/`
- **Recovery Time:** ~3 minutes
- **Prevention:** Persistent volumes (implemented) + maintain webhook config backup

### 5. **SonarQube Container Not Auto-Starting**
- **Issue:** SonarQube didn't restart automatically after Jenkins server reboot
- **Root Cause:** Docker container had no restart policy configured
- **Fix:** Added `--restart unless-stopped` to Docker run command
- **Recovery Time:** Manual restart required (~2 minutes)
- **Prevention:** Configure restart policies for all critical containers

### 6. **Jenkins Performance Degradation**
- **Issue:** Builds taking too long, timeouts during SonarQube analysis
- **Root Cause:** t2.2xlarge burstable instance CPU credits depleted; insufficient sustained performance
- **Fix:** Changed instance type to c6a.2xlarge (compute-optimized)
- **Recovery Time:** ~5 minutes (stop, change type, start)
- **Prevention:** Use compute-optimized instances for CI/CD workloads

### 7. **Jenkins Elastic IP Not Associated**
- **Issue:** Jenkins accessible at new public IP, but configured URLs used old IP
- **Root Cause:** Elastic IP not automatically reassociated after instance type change
- **Fix:** Manually associated Elastic IP (54.82.232.211) via AWS Console
- **Recovery Time:** ~2 minutes
- **Prevention:** Use Elastic IP + verify association after any instance changes

### 8. **Node.js Version Mismatch**
- **Issue:** Frontend builds failing with "npm install" errors
- **Root Cause:** Jenkins had Node.js 14.0, but SonarQube scanner required 14.17+
- **Fix:** Upgraded Node.js to 18.20.8 using NodeSource repository
- **Recovery Time:** ~10 minutes (install + verify)
- **Prevention:** Document required Node.js version; use specific version in Dockerfile

### 9. **Frontend Dockerfile Using Old Node Version**
- **Issue:** Frontend builds inconsistent due to Node 14 base image
- **Root Cause:** Dockerfile specified `FROM node:14` (outdated)
- **Fix:** Updated to `FROM node:18-alpine`
- **Recovery Time:** ~2 minutes (edit + rebuild)
- **Prevention:** Pin specific versions in Dockerfiles; regular dependency updates

### 10. **EKS Node Metadata Access Issues (IMDSv2)**
- **Issue:** ALB Ingress Controller crashing with "failed to get VPC ID from metadata"
- **Root Cause:** EC2 nodes enforcing IMDSv2, ALB controller couldn't access metadata
- **Fix:** Changed metadata options to "optional" (allow IMDSv1)
- **Recovery Time:** ~5 minutes (modify both nodes + verify)
- **Prevention:** Configure IRSA (IAM Roles for Service Accounts) for ALB controller

### 11. **ALB Controller Not Registering Targets**
- **Issue:** ALB created but no backend/frontend targets registered
- **Root Cause:** ALB controller couldn't fetch VPC/subnet info due to metadata access issues
- **Fix:** Fixed IMDSv2 issue (above); controller automatically registered targets
- **Recovery Time:** ~2 minutes after metadata fix
- **Prevention:** Proper IRSA configuration + monitoring ALB controller logs

### 12. **ALB Health Checks Failing (Wrong Path)**
- **Issue:** All backend targets showing "unhealthy" despite pods running fine
- **Root Cause:** ALB checking `/` (returns 404), not `/healthz` (returns 200)
- **Fix:** Added ingress annotations: `alb.ingress.kubernetes.io/healthcheck-path: /healthz`
- **Recovery Time:** ~1 minute (apply ingress + 30s for health checks)
- **Prevention:** Always explicitly configure health check paths in ingress annotations

### 13. **504 Gateway Timeout Errors**
- **Issue:** Application URL returning "504 Gateway Timeout"
- **Root Cause:** ALB had no healthy targets to route traffic (health check misconfiguration)
- **Fix:** Fixed health check path (above); targets became healthy, timeouts resolved
- **Recovery Time:** Immediate after health checks passed
- **Prevention:** Monitor ALB target health; verify health endpoints before deployment

### 14. **Jenkins JVM Configuration Not Optimized**
- **Issue:** Jenkins sluggish, frequent GC pauses during concurrent builds
- **Root Cause:** Default JVM settings not tuned for workload
- **Fix:** Added JVM opts: `-Xms2048m -Xmx4096m -XX:+UseG1GC -XX:MaxGCPauseMillis=200`
- **Recovery Time:** ~5 minutes (configure + restart Jenkins)
- **Prevention:** Set JVM options during initial Jenkins setup

---

## Recovery Time Summary

| Issue | Recovery Time | Complexity |
|-------|---------------|------------|
| EKS Node Group Recreation | ~10 min | Medium |
| SonarQube Persistent Storage | ~15 min | Medium |
| SonarQube Token Regeneration | ~5 min | Low |
| SonarQube Webhook Configuration | ~3 min | Low |
| SonarQube Restart Policy | ~2 min | Low |
| Jenkins Instance Type Change | ~5 min | Low |
| Jenkins Elastic IP Association | ~2 min | Low |
| Node.js Upgrade | ~10 min | Medium |
| Frontend Dockerfile Update | ~2 min | Low |
| EKS Node IMDSv2 Fix | ~5 min | Medium |
| ALB Target Registration | ~2 min | Low |
| ALB Health Check Fix | ~1 min | Low |
| 504 Timeout Resolution | Immediate | N/A |
| Jenkins JVM Tuning | ~5 min | Low |
| **Total Recovery Time** | **~67 minutes** | **Mixed** |

---

## Quick Recovery Roadmap (For Future Shutdowns)

### Phase 1: Infrastructure Startup (15 minutes)
1. ✅ Start Jenkins EC2 instance
2. ✅ Verify Elastic IP association (54.82.232.211)
3. ✅ Verify SonarQube container auto-started (`docker ps`)
4. ✅ If nodes were deleted: Recreate EKS node group (2x t2.medium)
5. ✅ Wait for nodes to be Ready (`kubectl get nodes`)

### Phase 2: Application Verification (10 minutes)
6. ✅ Verify all pods running (`kubectl get pods -n three-tier`)
7. ✅ Check MongoDB connection in backend logs
8. ✅ Verify ALB controller running (`kubectl get pods -n kube-system`)
9. ✅ Check ALB target groups for healthy targets (AWS Console)
10. ✅ Test application URL in browser

### Phase 3: Jenkins/SonarQube Validation (10 minutes)
11. ✅ Access Jenkins UI (http://54.82.232.211:8080)
12. ✅ Access SonarQube UI (http://54.82.232.211:9000)
13. ✅ Verify SonarQube webhook still configured
14. ✅ Run test build (backend or frontend) to verify Quality Gate

### Phase 4: Troubleshooting (If Issues Occur)
15. ✅ **If ALB targets unhealthy:** Check health check path in ingress
16. ✅ **If SonarQube lost data:** Check volume mounts exist (`docker inspect sonar`)
17. ✅ **If ALB controller crash:** Check node metadata settings (IMDSv1 enabled)
18. ✅ **If Jenkins sluggish:** Verify instance type (c6a.2xlarge) and JVM settings
19. ✅ **If builds fail:** Check Node.js version (`node --version` should be 18.x)

---

## Prevention Checklist (Before Shutdown)

### Documentation
- [ ] Document current EKS node group configuration (instance type, count, IAM role)
- [ ] Document Jenkins instance type and Elastic IP
- [ ] Backup SonarQube configuration (even with persistence, take export)
- [ ] Document all custom configurations made

### Persistence Configuration
- [ ] Verify SonarQube has persistent volumes mounted
- [ ] Verify SonarQube has restart policy configured
- [ ] Export/backup any critical data from ephemeral storage

### Configuration Backups
- [ ] Export SonarQube projects/quality gates (if possible)
- [ ] Document webhook URLs and tokens (in secure location)
- [ ] Save ingress.yaml with all annotations
- [ ] Backup Jenkins credentials (if possible)

### Testing Before Shutdown
- [ ] Test one full CI/CD pipeline run
- [ ] Verify application accessible via ALB
- [ ] Verify all health endpoints working
- [ ] Document any special startup procedures

---

## Improved Architecture Recommendations

Based on the recovery challenges documented above, several architectural improvements have been identified to make future operations more resilient and automated.

**For detailed implementation plans, priorities, and timelines, see:**
📋 **[FUTURE-ENHANCEMENTS.md](./FUTURE-ENHANCEMENTS.md)** - Comprehensive roadmap covering:
- Complete Infrastructure as Code (Terraform)
- Persistent storage for all stateful components
- IRSA for enhanced security
- Automated monitoring and alerting
- Cost optimization strategies
- And more...

---

## Commands Reference (Quick Copy-Paste)

### Infrastructure Verification
```bash
# Check Jenkins instance
aws ec2 describe-instances --instance-ids i-xxxxx --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress,InstanceType]'

# Check EKS nodes
kubectl get nodes
aws eks describe-nodegroup --cluster-name Three-Tier-K8s-EKS-Cluster --nodegroup-name ng-960b346f-new

# Check SonarQube
docker ps | grep sonar
docker inspect sonar --format='{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'
```

### Application Health Checks
```bash
# Check all pods
kubectl get pods -A

# Check ALB targets
aws elbv2 describe-target-health --target-group-arn <arn>

# Check ingress
kubectl get ingress -n three-tier
kubectl describe ingress mainlb -n three-tier
```

### Quick Fixes
```bash
# Fix SonarQube not running
docker start sonar

# Fix ALB controller crash
aws ec2 modify-instance-metadata-options --instance-id <node-id> --http-tokens optional

# Apply ingress changes
kubectl apply -f Kubernetes-Manifests-file/ingress.yaml

# Restart Jenkins
sudo systemctl restart jenkins
```

---

## Key Takeaways

### What Worked Well
✅ Persistent volumes prevented SonarQube data loss  
✅ Restart policy ensured SonarQube auto-started  
✅ Elastic IP maintained consistent Jenkins access  
✅ Instance type change improved performance  
✅ Health check annotations fixed ALB routing  

### What Needs Improvement
❌ EKS node group deletion requires full recreation (slow)  
❌ Manual configuration of SonarQube webhook after first setup  
❌ No automated health check validation script  
❌ IMDSv2 workaround instead of proper IRSA  
❌ Manual instance type changes not reflected in Terraform  

### Time Investment
- **Initial shutdown planning:** 30 min
- **Actual recovery time:** 67 min (first time)
- **Expected future recovery:** ~25 min (with this checklist)
- **ROI:** 42 minutes saved on each future recovery

---

## Related Documentation
- [AWS-COST-MANAGEMENT.md](./AWS-COST-MANAGEMENT.md) - Original shutdown procedures
- [NODE-GROUP-RECREATION-GUIDE.md](./NODE-GROUP-RECREATION-GUIDE.md) - Detailed node group steps
- [INFRASTRUCTURE-OPTIMIZATION-AND-FIXES.md](./INFRASTRUCTURE-OPTIMIZATION-AND-FIXES.md) - All fixes applied
- [SONARQUBE-FIX-GUIDE.md](./SONARQUBE-FIX-GUIDE.md) - SonarQube troubleshooting
- [JENKINS-INSTANCE-CHANGES.md](./JENKINS-INSTANCE-CHANGES.md) - Jenkins modifications

---

**Last Updated:** November 17, 2025  
**Status:** Active - Use this checklist for future shutdowns  
**Estimated Recovery Time:** 25-30 minutes (with checklist) vs 67 minutes (without)
