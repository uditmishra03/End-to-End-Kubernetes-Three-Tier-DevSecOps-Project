#!/bin/bash

################################################################################
# Kubernetes Cluster Shutdown Script
# Purpose: Safely shutdown EKS cluster for cost savings
# 
# IMPORTANT: This script handles ONLY the EKS cluster shutdown.
#            Jenkins server shutdown must be done MANUALLY after running this script.
#
# Usage: 
#   1. SSH to Jenkins server (or bastion server with AWS CLI + kubectl configured)
#   2. Run: ./shutdown-cluster.sh
#   3. After script completes, manually stop Jenkins EC2 instance from AWS Console
#
# Why manual Jenkins shutdown?
#   - This script runs FROM the Jenkins server
#   - Cannot stop the server it's running on
#   - You need to stop Jenkins from AWS Console or another machine
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EKS_CLUSTER_NAME="Three-Tier-K8s-EKS-Cluster"
REGION="us-east-1"
BACKUP_DIR="./cluster-backup-$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Kubernetes Cluster Shutdown Script${NC}"
echo -e "${BLUE}========================================${NC}"
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
# Function: Print error message
################################################################################
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

################################################################################
# Step 1: Create backup directory
################################################################################
print_header "Step 1: Creating Backup Directory"
mkdir -p "$BACKUP_DIR"
print_success "Created backup directory: $BACKUP_DIR"

################################################################################
# Step 2: Backup current cluster state
################################################################################
print_header "Step 2: Backing Up Cluster Configuration"

# Get current node groups
echo "Backing up node group configurations..."
aws eks list-nodegroups --cluster-name "$EKS_CLUSTER_NAME" --region "$REGION" \
    > "$BACKUP_DIR/nodegroups-list.json" 2>/dev/null || true

# Get details of each node group
NODEGROUPS=$(aws eks list-nodegroups --cluster-name "$EKS_CLUSTER_NAME" --region "$REGION" \
    --query 'nodegroups[]' --output text 2>/dev/null || echo "")

if [[ -n "$NODEGROUPS" ]]; then
    for ng in $NODEGROUPS; do
        echo "  - Backing up node group: $ng"
        aws eks describe-nodegroup --cluster-name "$EKS_CLUSTER_NAME" \
            --nodegroup-name "$ng" --region "$REGION" \
            > "$BACKUP_DIR/nodegroup-${ng}.json" 2>/dev/null || true
    done
    print_success "Node group configurations backed up"
else
    print_warning "No node groups found to backup"
fi

# Backup Kubernetes resources
if command -v kubectl &> /dev/null; then
    echo "Backing up Kubernetes resources..."
    kubectl get all -A -o yaml > "$BACKUP_DIR/k8s-all-resources.yaml" 2>/dev/null || true
    kubectl get ingress -A -o yaml > "$BACKUP_DIR/k8s-ingress.yaml" 2>/dev/null || true
    kubectl get pvc -A -o yaml > "$BACKUP_DIR/k8s-pvc.yaml" 2>/dev/null || true
    kubectl get configmap -A -o yaml > "$BACKUP_DIR/k8s-configmaps.yaml" 2>/dev/null || true
    kubectl get secret -A -o yaml > "$BACKUP_DIR/k8s-secrets.yaml" 2>/dev/null || true
    print_success "Kubernetes resources backed up"
else
    print_warning "kubectl not found, skipping Kubernetes backup"
fi

# Get current EC2 instances for reference
echo "Backing up EC2 instance information..."
aws ec2 describe-instances --region "$REGION" \
    --filters "Name=tag:Name,Values=Jenkins-server" \
    --query 'Reservations[0].Instances[0]' \
    > "$BACKUP_DIR/jenkins-instance.json" 2>/dev/null || true
print_success "EC2 instance information backed up"

################################################################################
# Step 3: Scale down applications (graceful shutdown)
################################################################################
print_header "Step 3: Scaling Down Applications"

if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
    echo "Scaling down deployments..."
    
    # Scale down application deployments
    kubectl scale deployment frontend --replicas=0 -n three-tier 2>/dev/null || true
    kubectl scale deployment api --replicas=0 -n three-tier 2>/dev/null || true
    
    # Wait a bit for graceful shutdown
    echo "Waiting for pods to terminate gracefully..."
    sleep 10
    
    print_success "Applications scaled down"
else
    print_warning "Cannot connect to cluster, skipping application scale down"
fi

################################################################################
# Step 4: Delete EKS Node Groups
################################################################################
print_header "Step 4: Deleting EKS Node Groups"

if [[ -n "$NODEGROUPS" ]]; then
    for ng in $NODEGROUPS; do
        echo "Deleting node group: $ng"
        aws eks delete-nodegroup --cluster-name "$EKS_CLUSTER_NAME" \
            --nodegroup-name "$ng" --region "$REGION" 2>/dev/null || {
            print_warning "Failed to delete node group $ng (may already be deleted)"
            continue
        }
        print_success "Initiated deletion of node group: $ng"
    done
    
    echo ""
    echo "Waiting for node groups to be deleted (this may take 3-5 minutes)..."
    
    for ng in $NODEGROUPS; do
        echo -n "  Waiting for $ng..."
        aws eks wait nodegroup-deleted --cluster-name "$EKS_CLUSTER_NAME" \
            --nodegroup-name "$ng" --region "$REGION" 2>/dev/null || true
        echo " deleted"
    done
    
    print_success "All node groups deleted"
else
    print_warning "No node groups found to delete"
fi

################################################################################
# Step 5: Jenkins Server Shutdown Instructions
################################################################################
print_header "Step 5: Manual Jenkins Server Shutdown Required"

# Get Jenkins instance ID for reference
JENKINS_INSTANCE_ID=$(aws ec2 describe-instances --region "$REGION" \
    --filters "Name=tag:Name,Values=Jenkins-server" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null || echo "")

if [[ -n "$JENKINS_INSTANCE_ID" && "$JENKINS_INSTANCE_ID" != "None" ]]; then
    echo ""
    echo -e "${YELLOW}⚠ IMPORTANT: Jenkins server is still running${NC}"
    echo ""
    echo "Jenkins Instance ID: $JENKINS_INSTANCE_ID"
    echo ""
    echo "To complete the shutdown and maximize cost savings, you must"
    echo "MANUALLY stop the Jenkins EC2 instance:"
    echo ""
    echo "Option 1 - AWS Console:"
    echo "  1. Go to EC2 Dashboard → Instances"
    echo "  2. Select instance: $JENKINS_INSTANCE_ID (Jenkins-server)"
    echo "  3. Instance State → Stop Instance"
    echo ""
    echo "Option 2 - AWS CLI (from another machine):"
    echo "  aws ec2 stop-instances --instance-ids $JENKINS_INSTANCE_ID --region $REGION"
    echo ""
    echo "Cost savings:"
    echo "  - Node groups deleted: ~\$1.20/day saved"
    echo "  - Jenkins stopped (manual): ~\$9.20/day saved"
    echo "  - Total: ~\$10.40/day saved"
    echo ""
    print_warning "Remember: Stop Jenkins server manually after this script completes!"
else
    print_warning "Jenkins instance not found or already stopped"
fi

################################################################################
# Step 6: Generate Shutdown Report
################################################################################
print_header "Step 6: Generating Shutdown Report"

cat > "$BACKUP_DIR/shutdown-report.txt" << EOF
Kubernetes Cluster Shutdown Report
Generated: $(date)
========================================

Cluster Information:
- Cluster Name: $EKS_CLUSTER_NAME
- Region: $REGION
- Node Groups Deleted: $NODEGROUPS

Jenkins Server:
- Status: STILL RUNNING (manual shutdown required)
- Instance ID: ${JENKINS_INSTANCE_ID:-"Not found"}

⚠ IMPORTANT - MANUAL ACTION REQUIRED:
To complete shutdown and maximize cost savings, you must manually
stop the Jenkins EC2 instance from AWS Console or CLI.

AWS Console: EC2 → Instances → $JENKINS_INSTANCE_ID → Stop Instance
AWS CLI:     aws ec2 stop-instances --instance-ids $JENKINS_INSTANCE_ID --region $REGION

Backup Location: $BACKUP_DIR

Recovery Instructions:
1. Manually start Jenkins EC2 instance from AWS Console
2. SSH to Jenkins server
3. Run: ./startup-cluster.sh
4. Wait 10-15 minutes for automated cluster recovery

For manual recovery, refer to:
   docs/NODE-GROUP-RECREATION-GUIDE.md
   docs/POST-SHUTDOWN-RECOVERY-CHECKLIST.md

Cost Savings (Estimated):
- Node Groups (2x t2.medium): ~\$1.20/day saved ✓ (DONE)
- Jenkins (manual stop): ~\$9.20/day saved (PENDING YOUR ACTION)
- Total Possible: ~\$10.40/day saved

Next Steps:
1. Stop Jenkins EC2 instance manually (see above)
2. When ready to restart:
   - Start Jenkins from AWS Console
   - SSH to Jenkins server  
   - Run: ./startup-cluster.sh (automated recovery)
EOF

cat "$BACKUP_DIR/shutdown-report.txt"
print_success "Shutdown report saved to: $BACKUP_DIR/shutdown-report.txt"

################################################################################
# Summary
################################################################################
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   EKS Cluster Shutdown Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Summary:"
echo "  ✓ Node groups deleted"
echo "  ✓ Cluster configuration backed up to: $BACKUP_DIR"
echo "  ⚠ Jenkins instance still running (manual stop required)"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  ⚠  ACTION REQUIRED: Stop Jenkins Manually${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "To complete shutdown and save ~\$9.20/day more:"
echo ""
echo "  1. Go to AWS Console → EC2 → Instances"
echo "  2. Select: $JENKINS_INSTANCE_ID (Jenkins-server)"
echo "  3. Instance State → Stop Instance"
echo ""
echo "Current savings: ~\$1.20/day (node groups deleted)"
echo "Potential total: ~\$10.40/day (with Jenkins stopped)"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  To Restart Everything:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  1. Start Jenkins EC2 from AWS Console"
echo "  2. SSH to Jenkins server"
echo "  3. Run: ${GREEN}./startup-cluster.sh${NC}"
echo "  4. Wait 10-15 minutes (fully automated)"
echo ""
