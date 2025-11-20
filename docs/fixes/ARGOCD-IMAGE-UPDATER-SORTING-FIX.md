# ArgoCD Image Updater - Lexicographic Sorting Issue Fix

## Date
November 20, 2025

## Issue Summary
ArgoCD Image Updater was not correctly identifying the latest container images due to a lexicographic sorting problem with image tags. The updater would select older images as "latest" because of improper tag formatting.

## Root Cause

### Problem
Docker image tags were using the format: `YYYYMMDD-{BUILD_NUMBER}` where BUILD_NUMBER was not zero-padded.

Example tags in ECR:
```
20251120-8
20251120-9
20251120-10   ← Should be newer than 9
20251120-11   ← Should be newer than 9
```

### Why It Failed
When ArgoCD Image Updater uses lexicographic (alphabetical) sorting to determine the "latest" image, it compares strings character by character:

```
Lexicographic order:
20251120-10   (comes BEFORE 9 alphabetically)
20251120-11   (comes BEFORE 9 alphabetically)
20251120-8
20251120-9    ← Incorrectly identified as "latest"!
```

This caused Image Updater to:
- **Frontend**: Downgrade from `:20251120-11` to `:20251120-9`
- **Backend**: Work initially but would fail once reaching double-digit build numbers

## Evidence from Logs

Image Updater logs showed the downgrade:
```
time="2025-11-20T14:35:55Z" level=info msg="Setting new image to 296062548155.dkr.ecr.us-east-1.amazonaws.com/frontend:20251120-9" alias=frontend application=frontend image_name=frontend image_tag=20251120-11 registry=296062548155.dkr.ecr.us-east-1.amazonaws.com
time="2025-11-20T14:35:55Z" level=info msg="Successfully updated image '...frontend:20251120-11' to '...frontend:20251120-9'"
```

## Solution

### Primary Fix: Zero-Padded Build Numbers

Updated both Jenkinsfiles to use 3-digit zero-padded build numbers:

**Before:**
```groovy
IMAGE_TAG = "${new Date().format('yyyyMMdd')}-${BUILD_NUMBER}"
// Generated: 20251120-9, 20251120-10, 20251120-11
```

**After:**
```groovy
IMAGE_TAG = "${new Date().format('yyyyMMdd')}-${String.format('%03d', BUILD_NUMBER.toInteger())}"
// Generated: 20251120-009, 20251120-010, 20251120-011
```

### Files Modified

1. **Frontend Jenkinsfile**: `three-tier-fe/Jenkinsfile`
   - Commit: `c96d811` - "test: Verify auto-update with zero-padded image tags"

2. **Backend Jenkinsfile**: `three-tier-be/Jenkinsfile`
   - Commit: `7746fab` - "test: Verify auto-update with zero-padded image tags"

### Correct Sorting After Fix

With zero-padded tags, lexicographic sorting now works correctly:
```
20251120-008
20251120-009
20251120-010
20251120-011
20251120-012  ← Correctly identified as latest
```

## Secondary Fixes Applied

### 1. Jenkins Post Section Errors
**Issue**: Credential binding errors in post-action sections
```
ERROR: ECR_REPO2
Required context class hudson.FilePath is missing
```

**Fix**: Simplified post sections to remove credential-dependent variables
- Removed `cleanWs()` calls that required workspace context
- Removed echo statements using `${REPOSITORY_URI}` and `${AWS_ECR_REPO_NAME}`

**Commits:**
- Backend: `70288b8` - "Fix: Simplify post section to avoid credential binding issues"
- Frontend: `62f1992` - "Fix: Add error handling for post actions"

### 2. Backend Credential ID Mismatch
**Issue**: Jenkins couldn't find credential `ECR_REPO2`

**Fix**: Changed to match frontend naming convention
```groovy
// Before
AWS_ECR_REPO_NAME = credentials('ECR_REPO2')

// After
AWS_ECR_REPO_NAME = credentials('ECR_REPO02')
```

**Commit**: `227d9aa` - "Fix: Change credential ID from ECR_REPO2 to ECR_REPO02"

### 3. GitHub API Rate Limiting
**Issue**: Jenkins hitting GitHub API rate limit (60 requests/hour)
```
Jenkins-Imposed API Limiter: Current quota has 14 remaining (1 over budget)
Still sleeping, now only 32 min remaining
```

**Fix**: Added GitHub Personal Access Token (PAT) to Jenkins
- Created new credential: "GitHub Webhook Token"
- Updated GitHub Server configuration in Jenkins
- New rate limit: 4995 requests/hour

### 4. Stuck Jenkins Builds
**Issue**: Builds stuck at "Started by user admin" after credential changes

**Fix**: Cleared Jenkins workspace and restarted service
```bash
cd /var/lib/jenkins/workspace/
sudo rm -rf MBP_Three-Tier-fe_MBP_master/
sudo rm -rf MBP_Three-Tier-be_MBP_master/
sudo rm -rf MBP_Three-Tier-*@tmp/
sudo systemctl restart jenkins
```

## Verification

### Before Fix
- Frontend stuck at: `:20251120-9` (older build)
- Backend at: `:20251120-4` 
- Image Updater was downgrading frontend

### After Fix
- Frontend deployed: `:20251120-017` ✅
- Backend deployed: `:20251120-017` ✅
- Image Updater correctly identifying latest tags

### Test Results
```bash
# Verified current images
kubectl get application frontend -n argocd -o jsonpath='{.spec.source.kustomize.images[0]}'
296062548155.dkr.ecr.us-east-1.amazonaws.com/frontend:20251120-017

kubectl get application backend -n argocd -o jsonpath='{.spec.source.kustomize.images[0]}'
296062548155.dkr.ecr.us-east-1.amazonaws.com/backend:20251120-017
```

## Configuration Details

### ArgoCD Image Updater Annotations
Both applications use identical annotation patterns:

```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: frontend=296062548155.dkr.ecr.us-east-1.amazonaws.com/frontend
  argocd-image-updater.argoproj.io/frontend.update-strategy: latest
  argocd-image-updater.argoproj.io/frontend.allow-tags: regexp:^[0-9-]+$
  argocd-image-updater.argoproj.io/frontend.force-update: "true"
  argocd-image-updater.argoproj.io/write-back-method: argocd
```

### Update Strategy
- **Method**: `latest` - selects the newest image based on tag sorting
- **Write-back**: `argocd` - updates ArgoCD Application spec directly (Kustomize image overrides)
- **Tag filter**: `regexp:^[0-9-]+$` - matches date-based tags like `20251120-009`
- **Check interval**: Every 2 minutes

## Lessons Learned

1. **Always use zero-padded numbers in version tags** when relying on lexicographic sorting
   - Use `001, 002, 003` instead of `1, 2, 3`
   - Prevents sorting issues when reaching double/triple digits

2. **Test Image Updater with double-digit build numbers** during initial setup
   - The issue only manifests after reaching build #10

3. **Monitor Image Updater logs** for unexpected "Setting new image" messages
   - Downgrades or unexpected version selections indicate sorting problems

4. **Avoid credential-dependent variables in Jenkins post sections**
   - Post sections execute outside the main pipeline context
   - Use simple echo statements or wrap in try-catch blocks

## Future Recommendations

### Alternative Tagging Strategies

If zero-padding is not preferred, consider:

1. **Semantic versioning**: `v1.0.0`, `v1.0.1`, `v1.1.0`
   - Requires more manual management
   - Works well with Image Updater's semantic version sorting

2. **Unix timestamps**: `1700492800`
   - Naturally sorts correctly
   - Less human-readable

3. **Combined format**: `20251120.009` or `20251120_009`
   - Still uses zero-padding for build number
   - More readable separation

### Monitoring Setup

Consider setting up alerts for:
- ArgoCD Image Updater errors in logs
- Unexpected application downgrades
- Images not updating within expected timeframe (>10 minutes)

## Related Documentation
- [ArgoCD Image Updater Configuration](../argocd-image-updater-config/)
- [Jenkins Pipeline Setup](../../Jenkinsfile)
- [Image Tagging Strategy](../IMAGE-TAGGING-STRATEGY.md)

## References
- ArgoCD Image Updater Docs: https://argocd-image-updater.readthedocs.io/
- Image Update Strategies: https://argocd-image-updater.readthedocs.io/en/stable/basics/update-strategies/
