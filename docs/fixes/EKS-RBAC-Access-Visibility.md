# EKS Console Shows No Resources: RBAC and Access Entry Fix

This document records the investigation and steps taken to fix the issue where the Amazon EKS console showed no Namespaces/Pods/ReplicaSets despite the cluster being Active.

## Symptoms
- EKS console Resources tab displayed: "No Pods/No Namespaces or you don't have permission to view them."
- `kubectl` from CLI could list nodes and namespaces when using a different principal.

## Root Cause
- The AWS console session was using an IAM Identity Center–backed admin role (assumed role via SSO), which was not mapped to any Kubernetes RBAC group.
- The cluster was configured with Authentication Mode: "EKS API and ConfigMap". Access policies alone (AmazonEKSAdminPolicy) do not grant Kubernetes RBAC. You must map the principal to Kubernetes groups via EKS Access Entries or the legacy `aws-auth` ConfigMap.

## Validation (CLI)
- Set kubeconfig and verify context:
```
aws eks update-kubeconfig --name Three-Tier-K8s-EKS-Cluster --region us-east-1
kubectl config current-context
```
- Confirm permissions and cluster health:
```
kubectl auth can-i --list
kubectl auth can-i list pods --all-namespaces
kubectl get nodes
kubectl get ns
```

## Fix Steps

1) Map devsecops IAM user (legacy `aws-auth`)
- Existing `aws-auth` only had node instance role. We appended `mapUsers` for `devsecops`:
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::296062548155:role/eksctl-Three-Tier-K8s-EKS-Cluster--NodeInstanceRole-1PLh0fSgNKtC
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    - userarn: arn:aws:iam::296062548155:user/devsecops
      username: devsecops
      groups:
        - system:masters
```
Apply:
```
kubectl apply -f aws-auth.yaml
kubectl -n kube-system get configmap aws-auth -o yaml
```
Result: Logging in as `devsecops` showed all resources in the EKS console.

2) Create a non-system Kubernetes group for admin and bind to cluster-admin
- Access Entries cannot use `system:*` groups; define a custom group, e.g. `eks-admins`:
```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: eks-admins-clusterrolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: Group
  name: eks-admins
  apiGroup: rbac.authorization.k8s.io
```
Apply:
```
kubectl apply -f - <<'EOF'
# manifest above
EOF
```

3) Update existing EKS Access Entry for Identity Center admin role
- Identify the principal ARN used by the console session:
```
aws sts get-caller-identity
# Arn: arn:aws:sts::296062548155:assumed-role/AWSReservedSSO_AdministratorAccess_<suffix>/Tarang
```
- Use the backing IAM role ARN listed under EKS → Access (IAM access entries), then attach the custom group:
```
aws eks update-access-entry \
  --cluster-name Three-Tier-K8s-EKS-Cluster \
  --principal-arn arn:aws:iam::296062548155:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_<suffix> \
  --kubernetes-groups eks-admins \
  --region us-east-1
```
- Verify:
```
aws eks list-access-entries --cluster-name Three-Tier-K8s-EKS-Cluster --region us-east-1
```
Result: EKS console (AdministratorAccess/Tarang) now lists Namespaces and workloads.

## Notes and Alternatives
- Access Entries disallow groups starting with `system:`; use custom names like `eks-admins` or `eks-auditors` and bind them via RBAC.
- For read-only visibility, bind `eks-auditors` to `ClusterRole` `view` and set the access entry `--kubernetes-groups eks-auditors`.
- If `create-access-entry` errors with `ResourceInUseException`, the principal already has an entry. Use `update-access-entry`.
- If Access Entry fails to resolve the role ARN, use the EKS console Access page to pick the role, or fall back to `aws-auth` `mapRoles` with the role ARN.

## Quick Verification Commands
```
kubectl auth can-i --as=tarang-admin list namespaces
kubectl get clusterrolebinding eks-admins-clusterrolebinding
aws eks list-access-entries --cluster-name Three-Tier-K8s-EKS-Cluster --region us-east-1
```

## Outcome
- Console visibility restored for both `devsecops` (via aws-auth) and the Identity Center admin session (via Access Entry + RBAC group).
- Cluster workloads, namespaces, and replica sets are visible in the EKS console.
