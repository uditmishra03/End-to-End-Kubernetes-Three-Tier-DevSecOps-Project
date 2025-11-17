#!/bin/bash
# Quick fix for slow Jenkins - Run this NOW on your existing server

echo "=== Emergency Jenkins Performance Fix ==="
echo ""

# 1. Stop SonarQube temporarily to free up resources
echo "1. Stopping SonarQube to free memory..."
docker stop sonar
echo ""

# 2. Update Jenkins JVM with aggressive settings for t3a.xlarge (4 vCPUs, 16GB RAM)
echo "2. Applying optimized Jenkins settings..."
sudo mkdir -p /etc/systemd/system/jenkins.service.d
sudo tee /etc/systemd/system/jenkins.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="JAVA_OPTS=-Djava.awt.headless=true -Xmx8g -Xms4g -XX:MaxMetaspaceSize=512m -XX:+UseG1GC -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+ParallelRefProcEnabled -XX:+DisableExplicitGC -XX:MaxGCPauseMillis=200 -Djava.net.preferIPv4Stack=true -Dhudson.model.DirectoryBrowserSupport.CSP= -Dhudson.security.csrf.DefaultCrumbIssuer.EXCLUDE_SESSION_ID=true"
Environment="JENKINS_OPTS=--sessionTimeout=1440"
LimitNOFILE=8192
EOF

# 3. Clean up disk space
echo "3. Cleaning up disk space..."
sudo apt-get clean
docker system prune -af --volumes
sudo journalctl --vacuum-time=3d

# 4. Restart Jenkins
echo "4. Restarting Jenkins..."
sudo systemctl daemon-reload
sudo systemctl restart jenkins

echo ""
echo "Waiting for Jenkins to start (60 seconds)..."
sleep 60

# 5. Restart SonarQube with limits
echo "5. Restarting SonarQube with memory limits..."
docker run -d --name sonar -p 9000:9000 \
  --restart=unless-stopped \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  --memory="4g" --memory-swap="4g" \
  --cpus="2" \
  sonarqube:lts-community

echo ""
echo "=== Quick Fix Applied ==="
echo ""
echo "Jenkins should be responsive now. Access at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "Memory allocation:"
echo "- Jenkins: 4-8GB heap"
echo "- SonarQube: 4GB limit, 2 CPU cores"
echo "- Docker & System: ~4GB"
echo ""
echo "If still slow, check CPU credits: AWS Console -> EC2 -> instance -> Monitoring tab"
echo "Solution: Switch from t2.2xlarge to t3a.xlarge (run terraform apply)"
