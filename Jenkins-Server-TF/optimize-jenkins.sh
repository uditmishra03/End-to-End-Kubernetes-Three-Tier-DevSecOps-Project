#!/bin/bash
# Script to optimize existing Jenkins server for better performance

echo "=== Optimizing Jenkins Server Performance ==="

# 1. Configure Jenkins JVM settings
echo "Configuring Jenkins JVM settings..."
sudo mkdir -p /etc/systemd/system/jenkins.service.d
sudo tee /etc/systemd/system/jenkins.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="JAVA_OPTS=-Djava.awt.headless=true -Xmx4g -Xms2g -XX:MaxMetaspaceSize=512m -XX:+UseG1GC -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+UseStringDeduplication -Dhudson.model.DirectoryBrowserSupport.CSP="
Environment="JENKINS_OPTS=--sessionTimeout=1440"
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

echo "Starting SonarQube with memory limits..."
docker run -d --name sonar -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  --memory="2g" --memory-swap="2g" \
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
echo "- Jenkins JVM: 2GB initial, 4GB max heap"
echo "- SonarQube: 2GB limit"
echo "- System: ~2GB for OS and other processes"
echo "- Total instance: t2.2xlarge (32GB RAM, 8 vCPUs)"
echo ""
echo "To check Jenkins status: sudo systemctl status jenkins"
echo "To view Jenkins logs: sudo journalctl -u jenkins -f"
