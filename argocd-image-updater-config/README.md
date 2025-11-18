# ArgoCD Image Updater IRSA Configuration

This directory contains the configuration files to set up ArgoCD Image Updater with IAM Roles for Service Accounts (IRSA) for ECR authentication.

## Prerequisites

1. EKS cluster with OIDC provider configured
2. IAM role created with ECR read permissions (see `../Jenkins-Server-TF/iam_for_argocd.tf`)
3. ArgoCD installed in the cluster

## Files

- `serviceaccount.yaml`: Service account with IRSA annotation for AWS authentication
- `ecr-credentials-helper.yaml`: ConfigMap containing the ECR login script
- `registries-configmap.yaml`: ConfigMap with ArgoCD Image Updater registry configuration
- `bootstrap-irsa.sh`: Automated script to apply all configurations
- `configure-deployment.sh`: (Legacy) Manual deployment configuration script

## Quick Setup

Run the bootstrap script to apply all configurations automatically:

```bash
chmod +x bootstrap-irsa.sh
./bootstrap-irsa.sh
```

This script will:
1. Apply the service account with IRSA annotation
2. Create the ECR credentials helper script
3. Configure the registry settings
4. Update the image updater deployment
5. Verify the configuration

## Manual Setup Instructions

If you prefer manual setup:

1. Apply the service account:
   ```bash
   kubectl apply -f serviceaccount.yaml
   ```

2. Apply the ECR credentials helper:
   ```bash
   kubectl apply -f ecr-credentials-helper.yaml
   ```

3. Apply the registries configuration:
   ```bash
   kubectl apply -f registries-configmap.yaml
   ```

4. Run the legacy configuration script:
   ```bash
   chmod +x configure-deployment.sh
   ./configure-deployment.sh
   ```

## How It Works

1. **IRSA Authentication**: The service account is annotated with IAM role ARN `arn:aws:iam::296062548155:role/ArgoCDImageUpdaterRole`
2. **Token Injection**: EKS automatically injects AWS credentials into the pod at `/var/run/secrets/eks.amazonaws.com/serviceaccount/token`
3. **ECR Login Script**: The `ecr-login.sh` script uses AWS CLI with IRSA credentials to fetch ECR tokens
4. **Registry Configuration**: ArgoCD Image Updater calls the script via `credentials: ext:/app/scripts/ecr-login.sh`
5. **Token Refresh**: IRSA tokens refresh automatically every 11 hours, eliminating the 12-hour expiration issue

## Architecture

```
┌─────────────────────────────────────────┐
│  ArgoCD Image Updater Pod               │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ IRSA Token (auto-refreshed)       │  │
│  │ /var/run/secrets/eks.amazonaws... │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ ECR Login Script                  │  │
│  │ /app/scripts/ecr-login.sh         │  │
│  │                                   │  │
│  │ Uses: AWS CLI + IRSA credentials  │  │
│  │ Output: AWS:<ecr-token>           │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ Registry Config                   │  │
│  │ credentials: ext:/app/scripts/... │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│  AWS ECR                                │
│  296062548155.dkr.ecr.us-east-1...      │
└─────────────────────────────────────────┘
```

## Verification

Check the service account annotation:
```bash
kubectl get serviceaccount argocd-image-updater -n argocd \
  -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'
```

Check the pod environment:
```bash
kubectl get pod -n argocd -l app.kubernetes.io/name=argocd-image-updater \
  -o jsonpath='{.spec.containers[0].env[?(@.name=="AWS_REGION")].value}'
```

Verify ECR authentication in logs:
```bash
kubectl logs -f deployment/argocd-image-updater -n argocd | grep -i "ecr\|registry\|auth"
```

Test the ECR login script directly:
```bash
POD=$(kubectl get pod -n argocd -l app.kubernetes.io/name=argocd-image-updater -o jsonpath='{.items[0].metadata.name}')
kubectl exec ${POD} -n argocd -- /app/scripts/ecr-login.sh
```

## Persistence After Cluster Restart

All configuration is stored in version-controlled YAML files. After cluster restart:

1. Ensure IAM resources exist (Terraform in `../Jenkins-Server-TF/`)
2. Run the bootstrap script: `./bootstrap-irsa.sh`
3. All configurations will be reapplied automatically

## Troubleshooting

**Issue**: "authorization token has expired"
- **Solution**: Run `./bootstrap-irsa.sh` to reapply all configurations

**Issue**: "invalid script output"
- **Solution**: Verify the script outputs `AWS:<token>` format by testing directly in the pod

**Issue**: "no basic auth credentials"
- **Solution**: Check that `registries-configmap.yaml` is applied and references the correct script path

**Issue**: Pod not assuming IAM role
- **Solution**: Verify IRSA annotation on service account and restart the pod
