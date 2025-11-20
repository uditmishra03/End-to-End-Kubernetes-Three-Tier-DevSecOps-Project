# Jenkins Performance Fix Guide

## Problem
Jenkins server is extremely slow and unresponsive after restart.

## Root Cause
1. **t2.2xlarge uses CPU credits** - Once exhausted, performance degrades by 90%
2. **No JVM heap configuration** - Jenkins running with default 512MB heap
3. **SonarQube consuming too much memory** - No resource limits set
4. **No automatic container restart** - SonarQube doesn't start after reboot

## Immediate Solution (For Existing Server)

### Step 1: Run Quick Fix Script
```bash
# Copy to server
scp -i your-key.pem Jenkins-Server-TF/quick-fix-jenkins.sh ubuntu@your-jenkins-ip:~

# SSH to server
ssh -i your-key.pem ubuntu@your-jenkins-ip

# Execute
chmod +x quick-fix-jenkins.sh
sudo ./quick-fix-jenkins.sh
```

This will:
- ✅ Allocate 3-6GB heap to Jenkins
- ✅ Limit SonarQube to 3GB RAM, 2 CPUs
- ✅ Clean up disk space
- ✅ Enable auto-restart for SonarQube

**Jenkins should be responsive in 1-2 minutes**

### Step 2: Check CPU Credits (Critical!)
```bash
# On AWS Console
EC2 → Select Instance → Monitoring tab → CPU Credit Balance

# If credits are LOW/ZERO, proceed to Step 3
```

### Step 3: Diagnose Issues (Optional)
```bash
# Copy diagnostic script
scp -i your-key.pem Jenkins-Server-TF/diagnose-jenkins.sh ubuntu@your-jenkins-ip:~

# Run diagnostics
chmod +x diagnose-jenkins.sh
./diagnose-jenkins.sh
```

## Permanent Solution (Recommended)

### Switch to t3.xlarge Instance

**Why?**
- t3.xlarge: Better CPU credits, unlimited mode available
- More cost-effective than t2.2xlarge
- Better baseline performance

**Comparison:**
| Instance | vCPU | RAM | Base CPU | Credits/hr | Cost/hr |
|----------|------|-----|----------|------------|---------|
| t2.2xlarge | 8 | 32GB | 26.5% | 81.6 | ~$0.37 |
| t3.xlarge | 4 | 16GB | 40% | 96 | ~$0.17 |

**Steps:**
```bash
# 1. Backup Jenkins data (if needed)
ssh -i your-key.pem ubuntu@your-jenkins-ip
sudo tar -czf jenkins-backup.tar.gz /var/lib/jenkins/

# 2. Update terraform and apply
cd Jenkins-Server-TF
terraform plan  # Review changes
terraform apply -auto-approve

# 3. Wait for new instance to be ready (5-10 minutes)
```

The new instance will automatically have:
- ✅ Optimized JVM settings (3-6GB heap)
- ✅ SonarQube with resource limits
- ✅ Auto-restart on reboot
- ✅ Better CPU performance
- ✅ Saves ~$145/month

## Alternative: Use t3.unlimited Mode

If you want to keep t2.2xlarge temporarily:
```bash
aws ec2 modify-instance-credit-specification \
    --instance-credit-specification "InstanceId=i-xxxxx,CpuCredits=unlimited"
```

**Warning:** This can increase costs if CPU usage is consistently high.

## Performance Optimizations Applied

### 1. Jenkins JVM Settings
- **Heap:** 3GB initial, 6GB max (was ~512MB default)
- **GC:** G1 collector with 200ms max pause
- **Options:** String deduplication, parallel ref processing
- **File descriptors:** Increased to 8192

### 2. SonarQube Container
- **Memory:** 3GB limit (from unlimited)
- **CPU:** 2 cores (from unlimited)
- **Restart:** unless-stopped (auto-restart on reboot)

### 3. System Optimizations
- File descriptor limits increased
- Docker resource cleanup
- Journal log retention reduced

## Verification

After applying fixes, check:
```bash
# 1. Jenkins is responsive
curl -I http://your-jenkins-ip:8080

# 2. Memory usage
free -h

# 3. Container status
docker stats --no-stream

# 4. Jenkins JVM settings
sudo systemctl show jenkins | grep JAVA_OPTS
```

## Troubleshooting

### Still Slow?
1. Check CPU credits in AWS Console
2. Run `diagnose-jenkins.sh` for detailed info
3. Consider upgrading to c5.xlarge (compute-optimized)

### Out of Memory?
```bash
# Reduce Jenkins heap
sudo sed -i 's/Xmx6g/Xmx4g/' /etc/systemd/system/jenkins.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart jenkins
```

### SonarQube Issues?
```bash
# Restart with more memory
docker stop sonar && docker rm sonar
docker run -d --name sonar -p 9000:9000 \
  --restart=unless-stopped \
  --memory="4g" --memory-swap="4g" \
  sonarqube:lts-community
```

## Cost Savings
- **Current:** t2.2xlarge = ~$270/month
- **Recommended:** t3.xlarge = ~$125/month
- **Savings:** ~$145/month (54% reduction)

## Files Modified
- `ec2.tf` - Changed instance type to t3.xlarge, increased volume to 40GB
- `tools-install.sh` - Added JVM optimization and auto-restart
- `optimize-jenkins.sh` - Full optimization script
- `quick-fix-jenkins.sh` - Emergency fix script
- `diagnose-jenkins.sh` - Diagnostic tool
