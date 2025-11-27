#!/bin/bash
# Bootstrap script to configure ArgoCD Image Updater with IRSA for ECR authentication
# Run this script after cluster creation or restart to ensure persistent ECR authentication

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="argocd"

echo "=========================================="
echo "ArgoCD Image Updater IRSA Bootstrap"
echo "=========================================="

# Step 1: Apply Service Account with IRSA annotation
echo "Step 1: Applying Service Account with IRSA annotation..."
kubectl apply -f "${SCRIPT_DIR}/serviceaccount.yaml"

# Step 2: Apply ECR credentials helper ConfigMap
echo "Step 2: Applying ECR credentials helper script..."
kubectl apply -f "${SCRIPT_DIR}/ecr-credentials-helper.yaml"

# Step 3: Apply registries ConfigMap
echo "Step 3: Applying registries configuration..."
kubectl apply -f "${SCRIPT_DIR}/registries-configmap.yaml"

# Step 4: Configure Image Updater Deployment
echo "Step 4: Configuring Image Updater deployment..."

# Add AWS_REGION environment variable
kubectl set env deployment/argocd-image-updater \
  -n ${NAMESPACE} \
  AWS_REGION=us-east-1

# Remove any existing AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
kubectl set env deployment/argocd-image-updater \
  -n ${NAMESPACE} \
  AWS_ACCESS_KEY_ID- \
  AWS_SECRET_ACCESS_KEY- \
  2>/dev/null || true

# Add volume for ECR credentials helper script
kubectl patch deployment argocd-image-updater -n ${NAMESPACE} --type json -p '[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "ecr-credentials-helper",
      "configMap": {
        "name": "ecr-credentials-helper",
        "defaultMode": 493
      }
    }
  }
]' 2>/dev/null || echo "Volume already exists or patch failed"

# Add volumeMount for ECR credentials helper script
kubectl patch deployment argocd-image-updater -n ${NAMESPACE} --type json -p '[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
      "name": "ecr-credentials-helper",
      "mountPath": "/app/scripts"
    }
  }
]' 2>/dev/null || echo "VolumeMount already exists or patch failed"

# Step 5: Wait for rollout
echo "Step 5: Waiting for deployment rollout..."
kubectl rollout status deployment/argocd-image-updater -n ${NAMESPACE} --timeout=120s

# Step 6: Verify configuration
echo ""
echo "=========================================="
echo "Verification"
echo "=========================================="

echo "Service Account IRSA annotation:"
kubectl get serviceaccount argocd-image-updater -n ${NAMESPACE} \
  -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}' && echo ""

echo ""
echo "Image Updater Pod AWS_REGION:"
POD_NAME=$(kubectl get pod -n ${NAMESPACE} -l app.kubernetes.io/name=argocd-image-updater -o jsonpath='{.items[0].metadata.name}')
kubectl get pod ${POD_NAME} -n ${NAMESPACE} \
  -o jsonpath='{.spec.containers[0].env[?(@.name=="AWS_REGION")].value}' && echo ""

echo ""
echo "ECR credentials script exists:"
kubectl exec ${POD_NAME} -n ${NAMESPACE} -- ls -lh /app/scripts/ecr-login.sh

echo ""
echo "IRSA token volume mounted:"
kubectl exec ${POD_NAME} -n ${NAMESPACE} -- ls -lh /var/run/secrets/eks.amazonaws.com/serviceaccount/token

echo ""
echo "=========================================="
echo "Bootstrap Complete!"
echo "=========================================="
echo "ArgoCD Image Updater is now configured with IRSA for ECR authentication."
echo "The authentication token will refresh automatically via IRSA."
echo ""
echo "To verify ECR authentication, check the image updater logs:"
echo "kubectl logs -f deployment/argocd-image-updater -n ${NAMESPACE}"
