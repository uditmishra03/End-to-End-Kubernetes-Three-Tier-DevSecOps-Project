# Jenkins Server Instance Changes

## Manual Changes Applied (November 17, 2025)

### 1. Instance Type Changed
- **From:** `t2.2xlarge` (8 vCPU, 32 GB RAM, $0.3712/hr)
- **To:** `c6a.2xlarge` (8 vCPU, 16 GB RAM, compute-optimized, ~$0.306/hr)
- **Reason:** Better CPU performance for Jenkins builds, memory was underutilized
- **Status:** Testing - if performance is good, update `ec2.tf`

### 2. Elastic IP Associated
- **Purpose:** Maintain consistent public IP across instance stop/start cycles
- **Benefit:** No need to update Jenkins URL or credentials after restarts
- **Cost:** ~$0.005/hr when instance is running, $0.005/hr when stopped (if not released)

---

## Current Issue: SonarQube Connection Failure

### Problem:
Jenkins is trying to connect to SonarQube using public IP `http://54.82.232.211:9000` instead of `localhost:9000`, causing connection timeout.

### Error:
```
ERROR: SonarQube server [http://54.82.232.211:9000] can not be reached
Caused by: java.net.SocketTimeoutException: Connect timed out
```

### Root Cause:
- SonarQube container is bound to `localhost:9000` only
- Jenkins SonarQube server configuration is using public IP
- Security group doesn't allow external access to port 9000 (and shouldn't for security)

### Solution:
**Update Jenkins SonarQube Server Configuration:**
1. Jenkins → Manage Jenkins → System
2. SonarQube servers → Server URL
3. Change from: `http://54.82.232.211:9000`
4. Change to: `http://localhost:9000`
5. Save and retry build

---

## TODO: Update Terraform Configuration

If `c6a.2xlarge` performance is satisfactory, update `ec2.tf`:

```terraform
resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.ami.image_id
  instance_type          = "c6a.2xlarge"  # Changed from t2.2xlarge
  key_name               = var.key-name
  subnet_id              = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.security-group.id]
  iam_instance_profile   = aws_iam_instance_profile.instance-profile.name
  root_block_device {
    volume_size = 30
  }
  user_data = templatefile("./tools-install.sh", {})

  tags = {
    Name = var.instance-name
  }
}
```

### Optional: Add Elastic IP to Terraform

```terraform
# Add this resource
resource "aws_eip" "jenkins_eip" {
  domain = "vpc"
  
  tags = {
    Name = "jenkins-server-eip"
  }
}

# Add this resource to associate EIP with instance
resource "aws_eip_association" "jenkins_eip_assoc" {
  instance_id   = aws_instance.ec2.id
  allocation_id = aws_eip.jenkins_eip.id
}

# Add this output to show the Elastic IP
output "jenkins_elastic_ip" {
  value       = aws_eip.jenkins_eip.public_ip
  description = "Elastic IP assigned to Jenkins server"
}
```

---

## Performance Comparison

### t2.2xlarge (Previous)
- **Type:** General Purpose
- **vCPUs:** 8
- **RAM:** 32 GB
- **Network:** Up to 5 Gbps
- **Cost:** $0.3712/hr (~$267/month if running 24/7)
- **Issue:** Memory underutilized, moderate CPU performance

### c6a.2xlarge (Current)
- **Type:** Compute Optimized
- **vCPUs:** 8 (AMD EPYC 7R13, better single-thread performance)
- **RAM:** 16 GB (sufficient for Jenkins + SonarQube)
- **Network:** Up to 12.5 Gbps
- **Cost:** ~$0.306/hr (~$220/month if running 24/7)
- **Benefit:** 
  - Better CPU performance for builds
  - Lower cost (~$47/month savings)
  - Faster network

---

## Cost Optimization Applied

### Daily Shutdown Strategy
Based on previous cost analysis:

**When Running:**
- Jenkins c6a.2xlarge: ~$0.306/hr × 8 hours = $2.45/day
- EKS Control Plane: $2.40/day (can't be stopped)
- **Total while working:** ~$4.85/day

**When Stopped:**
- EIP (if not released): $0.005/hr × 16 hours = $0.08/day
- EKS Control Plane: $2.40/day
- **Total while stopped:** ~$2.48/day

**Monthly Savings with 8hr/day usage:**
- Running 24/7: ~$267 (Jenkins) + $73 (EKS) = **$340/month**
- Running 8hr/day: ~$89 (Jenkins) + $73 (EKS) = **$162/month**
- **Savings: ~$178/month** (52% reduction)

---

## Testing Checklist

Before updating Terraform:

- [ ] Verify Jenkins builds complete successfully
- [ ] Check SonarQube analysis performance
- [ ] Monitor CPU and memory usage during peak builds
- [ ] Confirm Docker builds don't timeout
- [ ] Test concurrent pipeline executions
- [ ] Run for at least 3-5 days to validate stability

**Monitoring Commands:**
```bash
# Check resource usage
top -b -n 1 | head -n 20

# Monitor during builds
htop

# Check Docker stats
docker stats

# View Jenkins logs
sudo journalctl -u jenkins -f
```

---

**Last Updated:** November 17, 2025  
**Status:** Testing c6a.2xlarge performance
