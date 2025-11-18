# ArgoCD Image Updater Configuration for IRSA

This directory contains the Kubernetes manifests needed to configure the ArgoCD Image Updater to use IAM Roles for Service Accounts (IRSA) for ECR authentication.

## Prerequisites

1. The IAM role `ArgoCDImageUpdaterRole` must be created (defined in `Jenkins-Server-TF/iam_for_argocd.tf`)
2. Run `terraform apply` in the `Jenkins-Server-TF` directory to create the IAM resources
3. ArgoCD Image Updater must be installed in the `argocd` namespace

## Apply Configuration

After ArgoCD Image Updater is installed, apply these configurations:

```bash
# Apply the service account with IAM role annotation
kubectl apply -f argocd-image-updater-config/serviceaccount.yaml

# Add AWS_REGION environment variable to the deployment
kubectl set env deployment/argocd-image-updater -n argocd AWS_REGION=us-east-1

# Remove old static credentials (if they exist)
kubectl set env deployment/argocd-image-updater -n argocd AWS_ACCESS_KEY_ID- AWS_SECRET_ACCESS_KEY- AWS_DEFAULT_REGION-

# Restart the deployment to pick up changes
kubectl rollout restart deployment/argocd-image-updater -n argocd
```

## Verification

Check that the image updater is successfully authenticating to ECR:

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater --tail=50
```

You should NOT see "authorization token has expired" errors.

## How It Works

1. The Terraform code creates an IAM policy that grants ECR read permissions
2. The Terraform code creates an IAM role that can be assumed by the `argocd-image-updater` service account
3. The service account is annotated with the IAM role ARN
4. EKS automatically injects AWS credentials into the pod via IRSA
5. The image updater uses these auto-rotating credentials to authenticate to ECR
