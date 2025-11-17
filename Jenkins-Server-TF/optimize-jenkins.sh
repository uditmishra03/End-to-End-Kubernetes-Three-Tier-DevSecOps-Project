#!/bin/bash
# Script to optimize existing Jenkins server for better performance

echo "=== Optimizing Jenkins Server Performance ==="

# 1. Configure Jenkins JVM settings for t3a.xlarge (4 vCPUs, 16GB RAM) - Balanced for DevSecOps
echo "Configuring Jenkins JVM settings..."
sudo mkdir -p /etc/systemd/system/jenkins.service.d
sudo tee /etc/systemd/system/jenkins.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="JAVA_OPTS=-Djava.awt.headless=true -Xmx8g -Xms4g -XX:MaxMetaspaceSize=512m -XX:+UseG1GC -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+ParallelRefProcEnabled -XX:+DisableExplicitGC -XX:MaxGCPauseMillis=200 -Djava.net.preferIPv4Stack=true -Dhudson.model.DirectoryBrowserSupport.CSP=
-Dhudson.security.csrf.DefaultCrumbIssuer.EXCLUDE_SESSION_ID=true"
Environment="JENKINS_OPTS=--sessionTimeout=1440"
LimitNOFILE=8192
EOF

# 2. Reload systemd and restart Jenkins
echo "Restarting Jenkins with new settings..."
sudo systemctl daemon-reload
sudo systemctl restart jenkins

# 3. Optimize SonarQube container (stop and restart with memory limits)
echo "Optimizing SonarQube container..."
if docker ps -a | grep -q sonar; then
    echo "Stopping existing SonarQube container..."
    docker stop sonar
    docker rm sonar
fi

echo "Starting SonarQube with memory limits and auto-restart..."
docker run -d --name sonar -p 9000:9000 \
  --restart=unless-stopped \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  --memory="4g" --memory-swap="4g" \
  --cpus="2" \
  sonarqube:lts-community

# 4. Set system-level optimizations
echo "Applying system-level optimizations..."
# Increase file descriptors
echo "fs.file-max = 65536" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Set limits for Jenkins user
sudo tee -a /etc/security/limits.conf > /dev/null <<EOF
jenkins soft nofile 8192
jenkins hard nofile 8192
jenkins soft nproc 30654
jenkins hard nproc 30654
EOF

# 5. Clean up Docker resources to free memory
echo "Cleaning up Docker resources..."
docker system prune -f

echo "=== Optimization Complete ==="
echo "Jenkins should be available in 1-2 minutes at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "Memory allocation summary:"
echo "- Jenkins JVM: 4GB initial, 8GB max heap"
echo "- SonarQube: 4GB limit, 2 CPU cores"
echo "- Docker & System: ~4GB for builds and OS"
echo "- Optimized for: t3a.xlarge (16GB RAM, 4 vCPUs) - Balanced DevSecOps workload"
echo ""
echo "To check Jenkins status: sudo systemctl status jenkins"
echo "To view Jenkins logs: sudo journalctl -u jenkins -f"
