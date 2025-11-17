# SonarQube Build Failure - Troubleshooting Guide

## Problem: Jenkins Build Stuck at "waitForQualityGate"

### Symptoms:
- Jenkins build hangs at "Quality Check" stage
- SonarQube analysis completes but Quality Gate check never finishes
- Log shows: `SonarQube task 'xxx' status is 'IN_PROGRESS'`
- After server/container restart, builds fail with authentication errors

### Root Cause:
SonarQube container was running **without persistent volumes**, causing:
- All data (including tokens, projects, Quality Gates) to be lost on container restart
- Old task IDs to become invalid
- Authentication tokens to expire

---

## Immediate Fix (Current Stuck Build)

### 1. Abort Stuck Build
In Jenkins UI:
- Navigate to the stuck build
- Click **Abort** button (red ❌)

### 2. Verify SonarQube is Running
```bash
# Check container status
docker ps | grep sonar

# Check SonarQube health
curl http://localhost:9000/api/system/status
# Should return: {"status":"UP"}
```

### 3. Trigger New Build
- Go to your pipeline in Jenkins
- Click **Build Now**
- The new build will create a fresh task ID

---

## Permanent Fix (Prevent Future Issues)

### Option A: Use the Fix Script (Recommended)

**On Jenkins Server (Ubuntu):**

```bash
# Download and run the fix script
cd ~/temp-repo/Jenkins-Server-TF
chmod +x fix-sonarqube-persistence.sh
sudo ./fix-sonarqube-persistence.sh
```

This script will:
- Stop existing SonarQube container
- Backup existing data (if any)
- Create persistent volume directories
- Restart SonarQube with persistent storage
- Wait for SonarQube to be ready

### Option B: Manual Steps

**1. Stop and remove old container:**
```bash
docker stop sonar
docker rm sonar
```

**2. Create persistent directories:**
```bash
sudo mkdir -p /opt/sonarqube/{data,logs,extensions}
sudo chown -R 999:999 /opt/sonarqube
```

**3. Run with persistent volumes:**
```bash
docker run -d --name sonar -p 9000:9000 \
  --restart=unless-stopped \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  --memory="2g" --memory-swap="2g" \
  -v /opt/sonarqube/data:/opt/sonarqube/data \
  -v /opt/sonarqube/logs:/opt/sonarqube/logs \
  -v /opt/sonarqube/extensions:/opt/sonarqube/extensions \
  sonarqube:lts-community
```

**4. Wait for startup:**
```bash
# Monitor logs
docker logs sonar -f

# Or check status periodically
watch curl -s http://localhost:9000/api/system/status
```

---

## After Fixing Persistence

### 1. Generate Fresh Jenkins Token

**Via Browser:**
1. Login to SonarQube: `http://<jenkins-ip>:9000`
2. Username: `admin`, Password: `admin`
3. User menu → **My Account** → **Security** tab
4. Generate token with name: `jenkins-token`
5. **Copy the token immediately** (shown only once)

**Via CLI:**
```bash
curl -u admin:admin -X POST \
  "http://localhost:9000/api/user_tokens/generate?name=jenkins-token" \
  | jq -r '.token'
```

### 2. Update Jenkins Credential

1. Jenkins → **Manage Jenkins** → **Credentials**
2. Click **System** → **Global credentials**
3. Find credential ID: `sonar-token`
4. Click **Update**
5. Paste the new token in **Secret** field
6. **Save**

### 3. Test the Build

Trigger builds for both pipelines:
- Three-Tier-Backend-Multibranch
- Three-Tier-Frontend-Multibranch

---

## Verification

### Check Persistent Volumes:
```bash
# Verify directories exist and have data
ls -lah /opt/sonarqube/data
ls -lah /opt/sonarqube/extensions

# Check ownership
ls -ld /opt/sonarqube/*
# Should show: drwxr-xr-x 999 999
```

### Check Container Configuration:
```bash
# Verify restart policy
docker inspect sonar | grep -A 3 RestartPolicy
# Should show: "Name": "unless-stopped"

# Verify volumes are mounted
docker inspect sonar | grep -A 10 Mounts
# Should show /opt/sonarqube/data, logs, extensions
```

### Test Persistence:
```bash
# Restart container
docker restart sonar

# Wait 2 minutes, then check
curl http://localhost:9000/api/system/status

# Login and verify projects still exist
# Your tokens should still be valid
```

---

## Common Issues

### Issue: Container fails to start after adding volumes
**Cause:** Permission issues  
**Fix:**
```bash
sudo chown -R 999:999 /opt/sonarqube
docker restart sonar
```

### Issue: Old builds still stuck
**Cause:** Build is checking non-existent task ID  
**Fix:** Abort the build manually in Jenkins UI

### Issue: Authentication fails after token update
**Cause:** Credential not updated or wrong ID  
**Fix:** 
1. Verify credential ID is exactly: `sonar-token`
2. Check SonarQube server name in Jenkinsfile: `sonar-server`
3. Verify server URL in Jenkins config: `http://localhost:9000`

### Issue: Quality Gate never completes
**Cause:** Network connectivity or SonarQube overloaded  
**Fix:**
```bash
# Check if Jenkins can reach SonarQube
docker exec jenkins curl http://localhost:9000/api/system/status

# If fails, check if they're on same network
docker network inspect bridge
```

---

## Best Practices

✅ **Always use persistent volumes** for SonarQube  
✅ **Set restart policy** to `unless-stopped`  
✅ **Set memory limits** to prevent OOM issues  
✅ **Backup SonarQube data** before major changes:
   ```bash
   sudo tar -czf sonarqube-backup-$(date +%F).tar.gz /opt/sonarqube/data
   ```
✅ **Document tokens** in a secure password manager  
✅ **Test builds** after any infrastructure changes  

---

## Files Modified

- `tools-install.sh` - Updated to include persistent volumes
- `fix-sonarqube-persistence.sh` - New script for fixing existing installations

---

**Last Updated:** November 17, 2025  
**Status:** Fixed ✅
