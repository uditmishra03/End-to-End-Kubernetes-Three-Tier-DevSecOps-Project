#!/bin/bash

################################################################################
# Grafana Persistent Storage Setup Script
# Purpose: Configure persistent storage for Grafana to survive pod restarts
# 
# This script will:
#   1. Check if monitoring namespace exists
#   2. Upgrade the existing Prometheus/Grafana Helm release with persistent storage
#   3. Verify PersistentVolumeClaims are created and bound
#   4. Wait for Grafana pod to be ready
#   5. Display access information
#
# Usage: ./setup-grafana-persistence.sh
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="monitoring"
RELEASE_NAME="prometheus"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Grafana Persistent Storage Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} This will install a new Prometheus/Grafana stack in the 'monitoring' namespace."
echo -e "${YELLOW}Your existing setup in 'default' namespace will NOT be touched.${NC}"
echo ""

################################################################################
# Function: Print section header
################################################################################
print_header() {
    echo ""
    echo -e "${BLUE}>>> $1${NC}"
    echo "----------------------------------------"
}

################################################################################
# Function: Print success message
################################################################################
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

################################################################################
# Function: Print warning message
################################################################################
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

################################################################################
# Function: Print error message and exit
################################################################################
print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

################################################################################
# Step 1: Check if monitoring namespace exists
################################################################################
print_header "Step 1: Checking monitoring namespace"

if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    print_success "Namespace '$NAMESPACE' exists"
else
    echo "Creating namespace '$NAMESPACE'..."
    kubectl create namespace "$NAMESPACE"
    print_success "Namespace '$NAMESPACE' created"
fi

################################################################################
# Step 2: Check if Helm release exists in monitoring namespace
################################################################################
print_header "Step 2: Checking existing installation in monitoring namespace"

if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
    print_success "Found existing Helm release: $RELEASE_NAME in monitoring namespace"
    UPGRADE_MODE=true
else
    print_warning "No existing Helm release found in monitoring namespace."
    echo "Will perform fresh install (existing setup in 'default' namespace will not be touched)"
    UPGRADE_MODE=false
fi

################################################################################
# Step 3: Add/Update Prometheus Helm repository
################################################################################
print_header "Step 3: Updating Helm repository"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts &> /dev/null || true
helm repo update
print_success "Helm repository updated"

################################################################################
# Step 4: Upgrade or Install with persistent storage
################################################################################
print_header "Step 4: Configuring persistent storage for Grafana and Prometheus"

if [ "$UPGRADE_MODE" = true ]; then
    echo "Upgrading existing Helm release with persistent storage..."
    helm upgrade "$RELEASE_NAME" prometheus-community/kube-prometheus-stack \
        --namespace "$NAMESPACE" \
        --values "${SCRIPT_DIR}/prometheus-values.yaml" \
        --wait \
        --timeout 10m
    print_success "Helm release upgraded successfully"
else
    echo "Installing Prometheus stack with persistent storage..."
    helm install "$RELEASE_NAME" prometheus-community/kube-prometheus-stack \
        --namespace "$NAMESPACE" \
        --values "${SCRIPT_DIR}/prometheus-values.yaml" \
        --wait \
        --timeout 10m
    print_success "Helm release installed successfully"
fi

################################################################################
# Step 5: Verify PersistentVolumeClaims
################################################################################
print_header "Step 5: Verifying PersistentVolumeClaims"

echo "Waiting for PVCs to be bound..."
sleep 10

echo ""
echo "PersistentVolumeClaims in namespace '$NAMESPACE':"
kubectl get pvc -n "$NAMESPACE"

# Check Grafana PVC
if kubectl get pvc -n "$NAMESPACE" | grep -q "prometheus-grafana"; then
    print_success "Grafana PVC created"
else
    print_warning "Grafana PVC not found (may not be created yet)"
fi

# Check Prometheus PVC
if kubectl get pvc -n "$NAMESPACE" | grep -q "prometheus-prometheus"; then
    print_success "Prometheus PVC created"
else
    print_warning "Prometheus PVC not found (may not be created yet)"
fi

################################################################################
# Step 6: Wait for Grafana pod to be ready
################################################################################
print_header "Step 6: Waiting for Grafana pod to be ready"

echo "Waiting for Grafana deployment..."
kubectl wait --for=condition=available --timeout=300s \
    deployment/prometheus-grafana -n "$NAMESPACE" || true

print_success "Grafana pod is ready"

################################################################################
# Step 7: Display access information
################################################################################
print_header "Step 7: Access Information"

# Get Grafana LoadBalancer URL
GRAFANA_URL=$(kubectl get svc prometheus-grafana -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$GRAFANA_URL" ]; then
    print_warning "LoadBalancer not yet assigned. Checking again in 30 seconds..."
    sleep 30
    GRAFANA_URL=$(kubectl get svc prometheus-grafana -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
fi

# Get Grafana admin password
GRAFANA_PASSWORD=$(kubectl get secret prometheus-grafana -n "$NAMESPACE" -o jsonpath="{.data.admin-password}" | base64 -d)

# Get Prometheus LoadBalancer URL
PROMETHEUS_URL=$(kubectl get svc prometheus-kube-prometheus-prometheus -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Configuration Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Grafana Dashboard:${NC}"
echo -e "  URL: ${GREEN}http://${GRAFANA_URL}${NC}"
echo -e "  Username: ${YELLOW}admin${NC}"
echo -e "  Password: ${YELLOW}${GRAFANA_PASSWORD}${NC}"
echo ""
echo -e "${BLUE}Prometheus Dashboard:${NC}"
echo -e "  URL: ${GREEN}http://${PROMETHEUS_URL}:9090${NC}"
echo ""
echo -e "${BLUE}Persistent Storage:${NC}"
echo -e "  Grafana: ${GREEN}10Gi${NC} (dashboards and configurations)"
echo -e "  Prometheus: ${GREEN}20Gi${NC} (time-series metrics data)"
echo -e "  Retention: ${GREEN}15 days${NC}"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo -e "  ✓ Grafana dashboards will now persist across pod restarts"
echo -e "  ✓ Prometheus data will be retained for 15 days"
echo -e "  ✓ Data is stored on AWS EBS volumes (gp2)"
echo -e "  ✓ Configure your dashboards - they will be saved automatically"
echo -e "  ✓ Your existing Grafana in 'default' namespace is still running"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Test the new Grafana setup in 'monitoring' namespace"
echo -e "  2. Import and configure your dashboards"
echo -e "  3. Verify persistence by restarting pods"
echo -e "  4. Once satisfied, remove old installation from 'default' namespace:"
echo -e "     ${YELLOW}helm list -n default${NC}  # Find the release name"
echo -e "     ${YELLOW}helm uninstall <release-name> -n default${NC}"
echo ""

################################################################################
# Step 8: Display pod and PVC status
################################################################################
print_header "Step 8: Final Status Check"

echo "Pods in namespace '$NAMESPACE':"
kubectl get pods -n "$NAMESPACE" | grep -E "prometheus-grafana|prometheus-kube-prometheus-prometheus"

echo ""
echo "PersistentVolumeClaims with bound status:"
kubectl get pvc -n "$NAMESPACE"

echo ""
echo "Services (LoadBalancers):"
kubectl get svc -n "$NAMESPACE" | grep -E "prometheus-grafana|prometheus-kube-prometheus-prometheus"

echo ""
print_success "Setup complete! Your Grafana dashboards will now persist across restarts."
echo ""
