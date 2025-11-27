# ArgoCD Image Updater - Configuration and Sorting Fix

## Date
- **Initial Issue Fix:** November 20, 2025
- **Final Configuration Update:** November 27, 2025

## Issue Summary
ArgoCD Image Updater encountered two main issues:
1. **Lexicographic sorting problem** with non-zero-padded build numbers
2. **Invalid update-strategy configuration** causing image detection failures

Both issues have been resolved through proper configuration and tag formatting.

---

## Issue 1: Lexicographic Sorting Problem (November 20, 2025)

### Root Cause

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

### Before Fixes
- Frontend stuck at: `:20251120-9` (older build)
- Backend at: `:20251120-4` 
- Image Updater was downgrading frontend due to lexicographic sorting
- Invalid `update-strategy: semver` causing detection failures

### After Fixes (November 20, 2025)
- Frontend deployed: `:20251120-017` ✅
- Backend deployed: `:20251120-017` ✅
- Image Updater correctly identifying latest tags
- Zero-padded build numbers working

### After Configuration Update (November 27, 2025)
- Frontend and Backend using `update-strategy: latest` ✅
- Added `sort-tags: latest-first` for explicit sorting ✅
- Multiple builds tested successfully ✅
- Automatic deployment to EKS cluster working ✅

### Test Results
```bash
# Verified current images
kubectl get application frontend -n argocd -o jsonpath='{.spec.source.kustomize.images[0]}'
296062548155.dkr.ecr.us-east-1.amazonaws.com/frontend:20251127-XXX

kubectl get application backend -n argocd -o jsonpath='{.spec.source.kustomize.images[0]}'
296062548155.dkr.ecr.us-east-1.amazonaws.com/backend:20251127-XXX
```

---

## Issue 2: Update Strategy Configuration (November 27, 2025)

### Problem
Initial configuration used `update-strategy: semver` which is incompatible with date-based tags:

```yaml
# INCORRECT (Before)
annotations:
  argocd-image-updater.argoproj.io/frontend.update-strategy: semver
  argocd-image-updater.argoproj.io/frontend.allow-tags: regexp:^[0-9-]+$
```

**Why This Failed:**
- `semver` strategy expects semantic versioning format: `v1.0.0`, `v2.1.3`
- Date-based tags like `20251127-001` don't match semver pattern
- Image Updater couldn't determine "latest" version
- Updates were not triggered despite new images in ECR

### Solution
Changed update strategy from `semver` to `latest` with explicit sorting:

```yaml
# CORRECT (After - November 27, 2025)
annotations:
  argocd-image-updater.argoproj.io/image-list: frontend=296062548155.dkr.ecr.us-east-1.amazonaws.com/frontend
  argocd-image-updater.argoproj.io/frontend.update-strategy: latest
  argocd-image-updater.argoproj.io/frontend.allow-tags: regexp:^[0-9-]+$
  argocd-image-updater.argoproj.io/frontend.force-update: "true"
  argocd-image-updater.argoproj.io/frontend.sort-tags: latest-first
  argocd-image-updater.argoproj.io/write-back-method: argocd
```

### Configuration Changes Applied

**Files Modified:**
- `argocd-apps/backend-app.yaml`
- `argocd-apps/frontend-app.yaml`

**Commit:**
```bash
fix: Use valid update-strategy latest with sort-tags latest-first

- Changed update-strategy from 'semver' to 'latest' for date-based tags
- Added sort-tags: latest-first for explicit sorting order
- Date format YYYYMMDD-XXX now correctly identifies newest images
- Tested with multiple builds - automatic deployment working
```

### How It Works Now

**Update Strategy: `latest`**
- Picks the **most recent** image tag from filtered list
- Uses `sort-tags: latest-first` to sort in descending order
- For date format `YYYYMMDD-XXX`, higher values = newer images

**Example:**
```
Available tags in ECR:
- 20251125-001
- 20251126-003
- 20251127-005  ← Selected as "latest" (highest value)
```

**Tag Filtering: `allow-tags: regexp:^[0-9-]+$`**
- Only considers tags matching this pattern
- Matches: `20251127-001`, `20251127-002`
- Ignores: `latest`, `v1.0`, `test-abc`, untagged images

**Sorting: `sort-tags: latest-first`**
- Sorts tags in **descending** order (newest first)
- First tag in sorted list = selected image

**Write-back: `argocd`**
- Updates ArgoCD Application object directly in Kubernetes
- No Git write-back needed (fast deployment)
- Works with Kustomize image overrides

---

## Complete Workflow After Fixes

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
│    Creates tag: 20251127-XXX (zero-padded)             │
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
│    - Picks: 20251127-XXX (highest value)                │
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

---

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

### Final ArgoCD Image Updater Annotations (November 27, 2025)
Both applications use identical annotation patterns:

```yaml
annotations:
  # Image to monitor
  argocd-image-updater.argoproj.io/image-list: backend=296062548155.dkr.ecr.us-east-1.amazonaws.com/backend
  
  # Update strategy: 'latest' picks newest tag based on sorting
  argocd-image-updater.argoproj.io/backend.update-strategy: latest
  
  # Only consider tags matching date format YYYYMMDD-XXX
  argocd-image-updater.argoproj.io/backend.allow-tags: regexp:^[0-9-]+$
  
  # Force update even if tag unchanged (edge case handling)
  argocd-image-updater.argoproj.io/backend.force-update: "true"
  
  # Sort tags in descending order (newest first)
  argocd-image-updater.argoproj.io/backend.sort-tags: latest-first
  
  # Update ArgoCD Application directly (no Git write-back)
  argocd-image-updater.argoproj.io/write-back-method: argocd
```

### How Each Annotation Works

1. **`update-strategy: latest`**
   - Selects the most recent image from filtered and sorted list
   - Compatible with any tag format (date-based, numeric, etc.)
   - Alternative strategies: `semver`, `digest`, `name`

2. **`allow-tags: regexp:^[0-9-]+$`**
   - Filters tags to only include date-based format
   - Pattern matches: `20251127-001`, `20251127-002`
   - Ignores: `latest`, `v1.0.0`, `test`, untagged

3. **`sort-tags: latest-first`**
   - Explicit descending sort order
   - For date tags: `20251127-005` > `20251127-004` > `20251127-003`
   - First tag after sorting = selected image

4. **`force-update: "true"`**
   - Updates deployment even if tag name unchanged
   - Handles edge case of rebuilding same tag
   - Generally not needed but provides safety

5. **`write-back-method: argocd`**
   - Updates ArgoCD Application spec directly in Kubernetes
   - No Git repository modification
   - Fast deployment (no Git push overhead)
   - Perfect for repos where manifests are in app repos (three-tier-fe, three-tier-be)

### Update Strategy Comparison

| Strategy | Best For | Tag Format | Our Choice |
|----------|----------|------------|------------|
| `latest` | Any tag format | Any (date, numeric, custom) | ✅ **YES** - Works with `YYYYMMDD-XXX` |
| `semver` | Semantic versioning | `v1.0.0`, `v2.1.3` | ❌ NO - Doesn't match our date tags |
| `digest` | Immutable digests | SHA256 digests | ❌ NO - Less readable |
| `name` | Alphabetical | Custom patterns | ❌ NO - Same as lexicographic issue |

---

## Testing Results (November 27, 2025)

### Multiple Build Test ✅
**Scenario:** Pushed multiple commits in quick succession

**Results:**
- Build 1: Tag `20251127-001` → Detected and deployed
- Build 2: Tag `20251127-002` → Detected and deployed
- Build 3: Tag `20251127-003` → Detected and deployed
- Image Updater correctly picked latest tag each time
- No intermediate builds skipped or downgraded
- Pods restarted automatically with each new image

### Timing Verification ✅
**Observed Behavior:**
- Jenkins pipeline: 5-8 minutes (checkout to ECR push)
- Image Updater detection: 0-2 minutes (depends on 2-min poll cycle)
- Total deployment time: 7-10 minutes from `git push` to pods running
- ✅ Meets expected performance

### Sorting Verification ✅
**Test:** Created tags with varying numbers
```
Available tags:
- 20251127-001
- 20251127-002
- 20251127-009
- 20251127-010  ← Correctly identified as latest
```
**Result:** Zero-padded tags + `sort-tags: latest-first` = correct ordering

---

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
