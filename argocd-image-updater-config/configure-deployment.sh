#!/bin/bash
# Commands to configure ArgoCD Image Updater deployment for IRSA

# Add AWS_REGION environment variable
kubectl set env deployment/argocd-image-updater -n argocd AWS_REGION=us-east-1

# Remove old static AWS credentials (if they exist)
kubectl set env deployment/argocd-image-updater -n argocd AWS_ACCESS_KEY_ID- AWS_SECRET_ACCESS_KEY- AWS_DEFAULT_REGION-

# Restart the deployment to apply changes
kubectl rollout restart deployment/argocd-image-updater -n argocd

echo "Configuration applied. Check logs with:"
echo "kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater --tail=50"
