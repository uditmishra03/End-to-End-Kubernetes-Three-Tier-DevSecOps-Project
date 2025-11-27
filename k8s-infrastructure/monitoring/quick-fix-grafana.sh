#!/bin/bash

################################################################################
# Quick Fix: Grafana Persistent Storage
# Purpose: One-command fix for lost Grafana dashboards after pod restarts
# 
# Usage: ./quick-fix-grafana.sh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Quick Fix: Grafana Persistence${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "This script will configure persistent storage for Grafana"
echo "so your dashboards survive pod restarts."
echo ""

# Navigate to monitoring directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Run the setup script
if [ -f "setup-grafana-persistence.sh" ]; then
    chmod +x setup-grafana-persistence.sh
    ./setup-grafana-persistence.sh
else
    echo -e "${RED}Error: setup-grafana-persistence.sh not found${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Fix Applied Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Access Grafana using the URL displayed above"
echo "2. Login with username: admin and the password shown"
echo "3. Import your Kubernetes dashboards (IDs: 15760, 15761, 15762)"
echo "4. Your dashboards will now persist across restarts!"
echo ""
