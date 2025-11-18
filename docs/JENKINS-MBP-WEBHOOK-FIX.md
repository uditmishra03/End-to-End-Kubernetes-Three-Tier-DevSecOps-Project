# Jenkins Multibranch Pipeline (MBP) Webhook Configuration Fix

## Problem
Jenkins Multibranch Pipelines are not triggered automatically by GitHub webhooks. Manual "Scan Repository Now" is required to detect changes.

## Root Cause
Standard GitHub webhook URL (`/github-webhook/`) does not work with Multibranch Pipelines. MBP requires the **Multibranch Scan Webhook Trigger** plugin with a specific token-based endpoint.

---

## Solution

### Prerequisites
Ensure **Multibranch Scan Webhook Trigger** plugin is installed:
- Jenkins → Manage Jenkins → Manage Plugins → Installed
- Search for: "Multibranch Scan Webhook Trigger"
- If not installed, install it and restart Jenkins

---

## Configuration Steps

### Step 1: Configure Jenkins Jobs

#### Frontend MBP Configuration
1. Navigate to: **Jenkins** → **MBP** → **Three-Tier-Frontend-MBP** → **Configure**
2. Scroll to section: **"Scan Multibranch Pipeline Triggers"**
3. Enable: ☑ **"Scan by webhook"**
4. Set **Trigger token**: `frontend-webhook-token`
5. Click **Save**

#### Backend MBP Configuration
1. Navigate to: **Jenkins** → **MBP** → **Three-Tier-Backend-MBP** (or similar) → **Configure**
2. Scroll to section: **"Scan Multibranch Pipeline Triggers"**
3. Enable: ☑ **"Scan by webhook"**
4. Set **Trigger token**: `backend-webhook-token`
5. Click **Save**

---

### Step 2: Update GitHub Webhooks

#### Remove Old Webhook
1. Go to: **GitHub Repository** → **Settings** → **Webhooks**
2. Find webhook with URL: `http://3.227.140.48:8080/github-webhook/`
3. Click **Delete** (or Edit to update)

#### Add New Webhooks

##### Webhook #1 - Frontend
- **Payload URL**: `http://3.227.140.48:8080/multibranch-webhook-trigger/invoke?token=frontend-webhook-token`
- **Content type**: `application/json`
- **Secret**: (leave empty or add if needed)
- **SSL verification**: Disable (for HTTP) or configure for HTTPS
- **Events**: 
  - ☑ Just the push event
- Click **Add webhook**

##### Webhook #2 - Backend  
- **Payload URL**: `http://3.227.140.48:8080/multibranch-webhook-trigger/invoke?token=backend-webhook-token`
- **Content type**: `application/json`
- **Secret**: (leave empty or add if needed)
- **SSL verification**: Disable (for HTTP) or configure for HTTPS
- **Events**: 
  - ☑ Just the push event
- Click **Add webhook**

---

### Step 3: Test Webhooks

#### Test in GitHub
1. Go to webhook settings
2. Click on each webhook
3. Click **"Recent Deliveries"** tab
4. Click **"Redeliver"** button
5. Check response - should see **200 OK**

#### Test with Code Push
1. Make a small change to frontend code:
   ```bash
   cd Application-Code/frontend
   echo "// Test webhook" >> src/App.js
   git add .
   git commit -m "test: trigger frontend webhook"
   git push origin master
   ```

2. Verify in Jenkins:
   - Frontend MBP should automatically start scanning
   - Build should trigger for the master branch
   - No manual "Scan Repository Now" needed

3. Make a backend change:
   ```bash
   cd Application-Code/backend
   echo "// Test webhook" >> index.js
   git add .
   git commit -m "test: trigger backend webhook"
   git push origin master
   ```

4. Verify backend MBP also triggers automatically

---

## Alternative: Single Webhook with Generic Webhook Trigger

If you prefer ONE webhook for BOTH pipelines (more complex but cleaner):

### Install Generic Webhook Trigger Plugin
- Jenkins → Manage Jenkins → Manage Plugins
- Install: **Generic Webhook Trigger**

### Configure in Each MBP Job
Add the following in each Jenkinsfile at the top:

```groovy
pipeline {
    agent any
    
    triggers {
        GenericTrigger(
            genericVariables: [
                [key: 'ref', value: '$.ref'],
                [key: 'commits', value: '$.commits[*].modified[*]']
            ],
            genericHeaderVariables: [
            ],
            causeString: 'Triggered by GitHub webhook',
            token: 'github-webhook-token',
            regexpFilterText: '$ref',
            regexpFilterExpression: '^refs/heads/master$'
        )
    }
    
    // Rest of pipeline...
}
```

### Single GitHub Webhook
- **URL**: `http://3.227.140.48:8080/generic-webhook-trigger/invoke?token=github-webhook-token`
- This will trigger ALL configured pipelines

---

## Verification Checklist

- [ ] Multibranch Scan Webhook Trigger plugin installed
- [ ] Frontend MBP has "Scan by webhook" enabled with token
- [ ] Backend MBP has "Scan by webhook" enabled with token  
- [ ] Old GitHub webhook deleted or updated
- [ ] New webhooks added with correct tokens
- [ ] GitHub webhook delivery shows 200 OK
- [ ] Code push triggers build automatically
- [ ] No manual scan needed

---

## Troubleshooting

### Webhook Shows 403 Forbidden
**Issue**: CSRF protection blocking webhook  
**Solution**: 
1. Jenkins → Manage Jenkins → Configure Global Security
2. Under "CSRF Protection", ensure webhooks are allowed
3. Or add token to webhook URL

### Webhook Shows 404 Not Found
**Issue**: Wrong endpoint or plugin not installed  
**Solution**:
1. Verify URL format: `/multibranch-webhook-trigger/invoke?token=...`
2. Install "Multibranch Scan Webhook Trigger" plugin
3. Restart Jenkins

### Build Not Triggering Despite 200 OK
**Issue**: Token mismatch or branch filter  
**Solution**:
1. Verify token matches exactly in Jenkins and GitHub
2. Check Jenkins job configuration for branch discovery settings
3. Check Jenkins logs: Manage Jenkins → System Log

### Multiple Builds Triggering
**Issue**: Webhook configured multiple times  
**Solution**:
1. Check for duplicate webhooks in GitHub
2. Check for multiple trigger configurations in Jenkins

---

## Current Configuration

**Jenkins Instance**: `3.227.140.48:8080` (Static Elastic IP)  
**Repository**: `uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project`  
**Branch**: `master`

**Frontend MBP**: `Three-Tier-Frontend-MBP`  
**Backend MBP**: (verify name in Jenkins)

---

## Security Notes

⚠️ **Important**: 
- Keep webhook tokens secure
- Don't commit tokens to repository
- Use HTTPS for production (requires SSL certificate on Jenkins)
- Consider IP whitelisting for webhook sources (GitHub IPs)
- Rotate tokens periodically

---

## References

- [Multibranch Scan Webhook Trigger Plugin](https://plugins.jenkins.io/multibranch-scan-webhook-trigger/)
- [Generic Webhook Trigger Plugin](https://plugins.jenkins.io/generic-webhook-trigger/)
- [GitHub Webhooks Documentation](https://docs.github.com/en/webhooks)

---

**Last Updated**: November 18, 2025  
**Status**: Configuration fix documented - awaiting implementation
