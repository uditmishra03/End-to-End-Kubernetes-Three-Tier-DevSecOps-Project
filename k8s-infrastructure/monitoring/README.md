# Grafana Persistent Storage Configuration

This directory contains configuration files to enable persistent storage for Grafana and Prometheus, ensuring dashboards and metrics data survive pod restarts.

## Problem Statement

**Issue:** After restarting the cluster or when Grafana pods restart, all configured dashboards are lost because Grafana was deployed without persistent storage.

**Solution:** Configure AWS EBS-backed PersistentVolumes for both Grafana (dashboards) and Prometheus (metrics data).

## Files

- **`grafana-pvc.yaml`** - PersistentVolumeClaim for Grafana (10Gi)
- **`prometheus-values.yaml`** - Helm values with persistent storage configuration
- **`setup-grafana-persistence.sh`** - Automated setup script

## Quick Fix

Run the setup script to enable persistent storage:

```bash
cd k8s-infrastructure/monitoring
chmod +x setup-grafana-persistence.sh
./setup-grafana-persistence.sh
```

This script will:
1. ✅ Check if monitoring namespace exists
2. ✅ Upgrade existing Prometheus/Grafana Helm release with persistent storage
3. ✅ Create PersistentVolumeClaims (Grafana: 10Gi, Prometheus: 20Gi)
4. ✅ Wait for pods to be ready
5. ✅ Display access URLs and credentials

## What Gets Persisted

### Grafana (10Gi)
- Dashboard configurations
- User preferences
- Data source settings
- Custom dashboards
- Alert rules

### Prometheus (20Gi)
- Time-series metrics data
- Retention: 15 days
- Alerts and recording rules

### AlertManager (5Gi)
- Alert history
- Silences
- Configuration

## Storage Backend

**AWS EBS (gp2)** - General Purpose SSD
- StorageClass: `gp2` (default for EKS)
- AccessMode: `ReadWriteOnce`
- Automatically provisioned and attached to pods

## Manual Steps (Alternative)

If you prefer manual setup:

### 1. Add Helm Repository
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 2. Create Monitoring Namespace
```bash
kubectl create namespace monitoring
```

### 3. Upgrade Helm Release
```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values prometheus-values.yaml \
    --wait \
    --timeout 10m
```

### 4. Verify PVCs
```bash
kubectl get pvc -n monitoring
```

Expected output:
```
NAME                                STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS
prometheus-grafana                  Bound    pvc-xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx     10Gi       RWO            gp2
prometheus-prometheus-kube-...      Bound    pvc-yyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy     20Gi       RWO            gp2
alertmanager-prometheus-kube-...    Bound    pvc-zzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz     5Gi        RWO            gp2
```

## Access Grafana

### Get LoadBalancer URL
```bash
kubectl get svc prometheus-grafana -n monitoring
```

### Get Admin Password
```bash
kubectl get secret prometheus-grafana -n monitoring \
    -o jsonpath="{.data.admin-password}" | base64 -d
echo
```

### Login
- **URL:** `http://<LOADBALANCER-URL>`
- **Username:** `admin`
- **Password:** (from command above)

## Import Dashboards

Once logged into Grafana, import these Kubernetes dashboards:

1. Click **"+" → Import**
2. Enter Dashboard ID and click **Load**:
   - **15760** - Kubernetes / Views / Global
   - **15761** - Kubernetes / Views / Namespaces
   - **15762** - Kubernetes / Views / Pods
   - **6417** - Kubernetes Cluster Monitoring (via Prometheus)
   - **13770** - Kubernetes Cluster (Prometheus)
3. Select **Prometheus** data source
4. Click **Import**

**These dashboards will now persist across restarts!**

## Verify Persistence

Test that persistence is working:

### 1. Create or Import a Dashboard
```bash
# Import a test dashboard or create custom panels
```

### 2. Restart Grafana Pod
```bash
kubectl rollout restart deployment/prometheus-grafana -n monitoring
```

### 3. Wait for Pod to Come Back
```bash
kubectl wait --for=condition=available --timeout=300s \
    deployment/prometheus-grafana -n monitoring
```

### 4. Check Dashboard Still Exists
```bash
# Access Grafana URL and verify your dashboards are still there
```

## Integration with Startup Script

To automatically configure persistent storage on cluster restart, add to `scripts/startup-cluster.sh`:

```bash
################################################################################
# Step X: Configure Grafana Persistent Storage
################################################################################
print_header "Step X: Configuring Grafana Persistent Storage"

cd k8s-infrastructure/monitoring
./setup-grafana-persistence.sh
cd ../..

print_success "Grafana configured with persistent storage"
```

## Troubleshooting

### PVC Stuck in Pending
```bash
# Check PVC status
kubectl describe pvc prometheus-grafana -n monitoring

# Check if StorageClass exists
kubectl get storageclass

# Ensure EBS CSI driver is installed (EKS 1.23+)
kubectl get pods -n kube-system | grep ebs-csi
```

### Grafana Pod Not Starting
```bash
# Check pod events
kubectl describe pod -n monitoring -l app.kubernetes.io/name=grafana

# Check PVC binding
kubectl get pvc -n monitoring

# Check logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

### Data Not Persisting
```bash
# Verify volume is mounted
kubectl describe pod -n monitoring -l app.kubernetes.io/name=grafana | grep -A 5 "Mounts:"

# Check PVC is bound
kubectl get pvc prometheus-grafana -n monitoring

# Verify storage path
kubectl exec -n monitoring -it deployment/prometheus-grafana -- ls -la /var/lib/grafana
```

## Cost Considerations

**AWS EBS Volume Costs (us-east-1):**
- gp2: $0.10 per GB-month
- Grafana (10Gi): ~$1.00/month
- Prometheus (20Gi): ~$2.00/month
- AlertManager (5Gi): ~$0.50/month
- **Total: ~$3.50/month**

**Note:** Much cheaper than rebuilding dashboards after every restart!

## Cleanup

To remove persistent storage (will delete all data):

```bash
# Uninstall Helm release
helm uninstall prometheus -n monitoring

# Delete PVCs (this deletes the EBS volumes)
kubectl delete pvc --all -n monitoring

# Delete namespace
kubectl delete namespace monitoring
```

## References

- [Prometheus Operator Documentation](https://prometheus-operator.dev/)
- [Grafana Persistence Documentation](https://grafana.com/docs/grafana/latest/setup-grafana/configure-docker/#default-paths)
- [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [AWS EBS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html)
