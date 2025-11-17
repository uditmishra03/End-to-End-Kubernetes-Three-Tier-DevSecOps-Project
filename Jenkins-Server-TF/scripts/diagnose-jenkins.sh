#!/bin/bash
# Script to diagnose Jenkins server performance issues

echo "=== Jenkins Server Performance Diagnostics ==="
echo ""

# 1. Check CPU credits (for t2 instances)
echo "1. CPU Credits Status:"
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
echo "Instance ID: $INSTANCE_ID"
echo "Note: Check AWS Console -> EC2 -> Monitoring tab for CPU credit balance"
echo ""

# 2. Check memory usage
echo "2. Memory Usage:"
free -h
echo ""

# 3. Check CPU usage
echo "3. CPU Load Average:"
uptime
echo ""

# 4. Check disk usage
echo "4. Disk Usage:"
df -h
echo ""

# 5. Check Jenkins process
echo "5. Jenkins Process Info:"
ps aux | grep jenkins | grep -v grep
echo ""

# 6. Check Docker containers
echo "6. Docker Containers:"
docker stats --no-stream
echo ""

# 7. Check Jenkins logs for errors
echo "7. Recent Jenkins Logs (last 20 lines):"
sudo journalctl -u jenkins -n 20 --no-pager
echo ""

# 8. Check system load
echo "8. Top Processes by CPU:"
ps aux --sort=-%cpu | head -10
echo ""

echo "9. Top Processes by Memory:"
ps aux --sort=-%mem | head -10
echo ""

# 10. Check Jenkins Java heap usage
echo "10. Jenkins JVM Settings:"
sudo systemctl show jenkins | grep Environment
echo ""

echo "=== Diagnostics Complete ==="
echo ""
echo "Common Issues:"
echo "- If CPU credits are low/zero: Switch from t2 to t3 or m5/c5 instances"
echo "- If memory is >80% used: Increase JVM heap or upgrade instance"
echo "- If disk is >80% full: Clean up or increase volume size"
