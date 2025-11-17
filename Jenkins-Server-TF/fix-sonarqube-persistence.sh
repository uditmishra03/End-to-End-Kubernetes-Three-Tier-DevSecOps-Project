#!/bin/bash
# Script to fix SonarQube with persistent storage
# Run this on Jenkins server to prevent data loss on container restarts

echo "==================================="
echo "SonarQube Persistence Fix Script"
echo "==================================="
echo ""

# Stop existing SonarQube container
echo "Stopping existing SonarQube container..."
docker stop sonar || true

# Backup any existing data if container has it
echo "Backing up existing SonarQube data (if any)..."
docker cp sonar:/opt/sonarqube/data /tmp/sonarqube-backup-data 2>/dev/null || echo "No data to backup"
docker cp sonar:/opt/sonarqube/extensions /tmp/sonarqube-backup-extensions 2>/dev/null || echo "No extensions to backup"

# Remove old container
echo "Removing old container..."
docker rm sonar

# Create persistent directories
echo "Creating persistent storage directories..."
sudo mkdir -p /opt/sonarqube/{data,logs,extensions}

# Restore backup if exists
if [ -d "/tmp/sonarqube-backup-data" ]; then
    echo "Restoring backed up data..."
    sudo cp -r /tmp/sonarqube-backup-data/* /opt/sonarqube/data/
    sudo cp -r /tmp/sonarqube-backup-extensions/* /opt/sonarqube/extensions/
    sudo rm -rf /tmp/sonarqube-backup-*
fi

# Set correct ownership
echo "Setting correct permissions..."
sudo chown -R 999:999 /opt/sonarqube

# Run new container with persistent volumes
echo "Starting SonarQube with persistent storage..."
docker run -d --name sonar -p 9000:9000 \
  --restart=unless-stopped \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  --memory="2g" --memory-swap="2g" \
  -v /opt/sonarqube/data:/opt/sonarqube/data \
  -v /opt/sonarqube/logs:/opt/sonarqube/logs \
  -v /opt/sonarqube/extensions:/opt/sonarqube/extensions \
  sonarqube:lts-community

echo ""
echo "Waiting for SonarQube to start (this takes 2-3 minutes)..."
echo "Monitoring container logs..."
echo ""

# Wait for SonarQube to be ready
COUNTER=0
MAX_WAIT=180  # 3 minutes

while [ $COUNTER -lt $MAX_WAIT ]; do
    STATUS=$(curl -s http://localhost:9000/api/system/status 2>/dev/null | grep -o '"status":"UP"' || echo "")
    
    if [ ! -z "$STATUS" ]; then
        echo ""
        echo "✅ SonarQube is UP and running!"
        echo ""
        echo "==================================="
        echo "Next Steps:"
        echo "==================================="
        echo "1. Login to SonarQube: http://localhost:9000"
        echo "   Username: admin"
        echo "   Password: admin"
        echo ""
        echo "2. Generate a new token:"
        echo "   User Menu → My Account → Security → Generate Token"
        echo ""
        echo "3. Or use this command to generate token via CLI:"
        echo "   curl -u admin:admin -X POST \"http://localhost:9000/api/user_tokens/generate?name=jenkins-token\" | jq -r '.token'"
        echo ""
        echo "4. Update Jenkins credential 'sonar-token' with the new token"
        echo ""
        echo "5. Abort any stuck builds and trigger new builds"
        echo ""
        echo "✅ SonarQube data will now persist across container restarts!"
        echo "==================================="
        exit 0
    fi
    
    echo -n "."
    sleep 5
    COUNTER=$((COUNTER + 5))
done

echo ""
echo "⚠️  SonarQube is taking longer than expected to start."
echo "Check logs with: docker logs sonar -f"
