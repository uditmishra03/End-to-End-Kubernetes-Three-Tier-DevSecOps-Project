#!/bin/bash

################################################################################
# Cleanup Old Grafana/Prometheus from Default Namespace
# Purpose: Remove old monitoring stack after verifying new one works
# 
# ⚠️  WARNING: Only run this AFTER confirming new setup in 'monitoring' namespace works!
#
# Usage: ./cleanup-old-monitoring.sh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}  ⚠️  WARNING - CLEANUP SCRIPT${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo -e "${YELLOW}This script will remove the OLD Prometheus/Grafana installation${NC}"
echo -e "${YELLOW}from the 'default' namespace.${NC}"
echo ""
echo -e "${RED}Prerequisites:${NC}"
echo -e "  ✓ New monitoring stack in 'monitoring' namespace is working"
echo -e "  ✓ All dashboards have been reconfigured in new Grafana"
echo -e "  ✓ You have verified persistence works (tested pod restarts)"
echo ""
echo -e "${YELLOW}This will delete:${NC}"
echo -e "  - Grafana deployment in 'default' namespace"
echo -e "  - Prometheus StatefulSet in 'default' namespace"
echo -e "  - All related services and ConfigMaps"
echo -e "  - LoadBalancer services (old URLs will stop working)"
echo ""

# Prompt for confirmation
read -p "Are you sure you want to proceed? (type 'yes' to confirm): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo ""
    echo -e "${GREEN}Cleanup cancelled. No changes made.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Starting cleanup...${NC}"
echo ""

################################################################################
# Step 1: List existing Helm releases in default namespace
################################################################################
echo -e "${BLUE}>>> Step 1: Identifying Helm releases in 'default' namespace${NC}"
echo "----------------------------------------"

RELEASES=$(helm list -n default -q)

if [[ -z "$RELEASES" ]]; then
    echo -e "${YELLOW}No Helm releases found in 'default' namespace.${NC}"
    echo "Checking for standalone resources..."
else
    echo "Found Helm releases:"
    echo "$RELEASES"
    echo ""
    
    # Prompt for each release
    for release in $RELEASES; do
        echo -e "${YELLOW}Release: $release${NC}"
        helm list -n default | grep "$release"
        
        read -p "Remove this release? (yes/no): " REMOVE
        if [[ "$REMOVE" == "yes" ]]; then
            echo "Uninstalling $release..."
            helm uninstall "$release" -n default
            echo -e "${GREEN}✓ Removed $release${NC}"
        else
            echo -e "${YELLOW}⊘ Skipped $release${NC}"
        fi
        echo ""
    done
fi

################################################################################
# Step 2: Remove standalone resources (if not managed by Helm)
################################################################################
echo ""
echo -e "${BLUE}>>> Step 2: Checking for standalone monitoring resources${NC}"
echo "----------------------------------------"

# Check for Grafana deployments
GRAFANA_DEPLOYS=$(kubectl get deployments -n default -o name | grep -i grafana || echo "")
if [[ -n "$GRAFANA_DEPLOYS" ]]; then
    echo "Found Grafana deployments:"
    echo "$GRAFANA_DEPLOYS"
    read -p "Delete these deployments? (yes/no): " DELETE
    if [[ "$DELETE" == "yes" ]]; then
        echo "$GRAFANA_DEPLOYS" | xargs kubectl delete -n default
        echo -e "${GREEN}✓ Deleted Grafana deployments${NC}"
    fi
fi

# Check for Prometheus StatefulSets
PROM_STS=$(kubectl get statefulsets -n default -o name | grep -i prometheus || echo "")
if [[ -n "$PROM_STS" ]]; then
    echo "Found Prometheus StatefulSets:"
    echo "$PROM_STS"
    read -p "Delete these StatefulSets? (yes/no): " DELETE
    if [[ "$DELETE" == "yes" ]]; then
        echo "$PROM_STS" | xargs kubectl delete -n default
        echo -e "${GREEN}✓ Deleted Prometheus StatefulSets${NC}"
    fi
fi

# Check for monitoring services
MON_SERVICES=$(kubectl get services -n default -o name | grep -E "grafana|prometheus|alertmanager" || echo "")
if [[ -n "$MON_SERVICES" ]]; then
    echo "Found monitoring services:"
    echo "$MON_SERVICES"
    read -p "Delete these services? (yes/no): " DELETE
    if [[ "$DELETE" == "yes" ]]; then
        echo "$MON_SERVICES" | xargs kubectl delete -n default
        echo -e "${GREEN}✓ Deleted monitoring services${NC}"
    fi
fi

################################################################################
# Step 3: Summary
################################################################################
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Cleanup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Remaining resources in 'default' namespace:"
kubectl get pods,svc -n default | grep -E "grafana|prometheus|alertmanager" || echo "  (none)"
echo ""
echo "Your new monitoring stack in 'monitoring' namespace:"
kubectl get pods,svc -n monitoring
echo ""
echo -e "${BLUE}New Grafana URL:${NC}"
NEW_GRAFANA_URL=$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending...")
echo "  http://${NEW_GRAFANA_URL}"
echo ""
echo -e "${GREEN}✓ Old monitoring stack removed successfully${NC}"
echo ""
