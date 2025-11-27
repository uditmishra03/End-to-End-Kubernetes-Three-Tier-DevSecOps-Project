# Grafana Persistence Fix Documentation

## Problem Description

**Issue:** Grafana dashboards disappear after cluster or pod restarts  
**Root Cause:** Grafana was deployed without persistent storage (PersistentVolume)  
**Impact:** All configured dashboards, data sources, and settings lost on every restart  
**Date Identified:** November 27, 2025  
**Date Fixed:** November 27, 2025  

---

## Solution Overview

Configure AWS EBS-backed PersistentVolumes for:
1. **Grafana** - Dashboard configurations and user data (10Gi)
2. **Prometheus** - Time-series metrics data (20Gi)
3. **AlertManager** - Alert history and silences (5Gi)

**Total Storage:** 35Gi (~$3.50/month on AWS)  
**Benefit:** Dashboards persist indefinitely across restarts

---

## Quick Fix (Immediate Solution)

### Option 1: One-Command Fix
```bash
cd k8s-infrastructure/monitoring
chmod +x quick-fix-grafana.sh
./quick-fix-grafana.sh
```

### Option 2: Direct Script Execution
```bash
cd k8s-infrastructure/monitoring
chmod +x setup-grafana-persistence.sh
./setup-grafana-persistence.sh
```

**Time Required:** 5-10 minutes  
**Downtime:** Minimal (rolling upgrade)  
**Data Loss:** None (existing Prometheus data preserved)

---

## What the Fix Does

### 1. Creates PersistentVolumeClaims
```yaml
# Grafana PVC (10Gi)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana-pvc
  namespace: monitoring
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: 10Gi
```

### 2. Upgrades Helm Release with Persistent Storage
```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values prometheus-values.yaml \
    --wait \
    --timeout 10m
```

### 3. Mounts Volumes to Pods
- **Grafana Pod:** `/var/lib/grafana` → 10Gi EBS volume
- **Prometheus Pod:** `/prometheus` → 20Gi EBS volume
- **AlertManager Pod:** `/alertmanager` → 5Gi EBS volume

### 4. Configures Data Retention
- **Prometheus:** 15 days of metrics data
- **Grafana:** Indefinite dashboard retention
- **AlertManager:** Indefinite alert history

---

## Technical Details

### Storage Configuration

| Component | Size | Path | Retention | Purpose |
|-----------|------|------|-----------|---------|
| **Grafana** | 10Gi | `/var/lib/grafana` | Indefinite | Dashboards, datasources, settings |
| **Prometheus** | 20Gi | `/prometheus` | 15 days | Time-series metrics data |
| **AlertManager** | 5Gi | `/alertmanager` | Indefinite | Alert history, silences |

### AWS EBS Volume Specs
- **StorageClass:** `gp2` (General Purpose SSD)
- **AccessMode:** `ReadWriteOnce` (single-node mounting)
- **Provisioner:** `ebs.csi.aws.com` (EBS CSI driver)
- **Availability:** Same AZ as pod

### Cost Breakdown (us-east-1)
```
Grafana:       10Gi × $0.10/GB/month = $1.00/month
Prometheus:    20Gi × $0.10/GB/month = $2.00/month
AlertManager:   5Gi × $0.10/GB/month = $0.50/month
----------------------------------------
Total:                                   $3.50/month
```

---

## Verification Steps

### 1. Check PVCs are Bound
```bash
kubectl get pvc -n monitoring
```

Expected output:
```
NAME                                    STATUS   VOLUME                                     CAPACITY   STORAGECLASS
prometheus-grafana                      Bound    pvc-abc123...                             10Gi       gp2
prometheus-prometheus-kube-...          Bound    pvc-def456...                             20Gi       gp2
alertmanager-prometheus-kube-...        Bound    pvc-ghi789...                             5Gi        gp2
```

### 2. Verify Pods are Running
```bash
kubectl get pods -n monitoring | grep -E "grafana|prometheus"
```

### 3. Check Volume Mounts
```bash
kubectl describe pod -n monitoring -l app.kubernetes.io/name=grafana | grep -A 5 "Mounts:"
```

Should show:
```
Mounts:
  /var/lib/grafana from storage (rw)
```

### 4. Test Persistence

#### Step 1: Import a Dashboard
```bash
# Access Grafana → Import dashboard ID 15760
```

#### Step 2: Restart Grafana Pod
```bash
kubectl rollout restart deployment/prometheus-grafana -n monitoring
```

#### Step 3: Wait for Pod Ready
```bash
kubectl wait --for=condition=available --timeout=300s \
    deployment/prometheus-grafana -n monitoring
```

#### Step 4: Verify Dashboard Persists
```bash
# Access Grafana again → Dashboard should still be there
```

---

## Integration with Startup Script

The fix is now integrated into `scripts/startup-cluster.sh` at **Step 8.5**.

### Automatic Execution
When you run `./startup-cluster.sh`, it will:
1. ✅ Create node groups
2. ✅ Deploy applications
3. ✅ Configure ArgoCD
4. ✅ **Configure Grafana persistent storage** (NEW)
5. ✅ Verify ALB health
6. ✅ Test endpoints

### Manual Trigger
If you've already started the cluster:
```bash
cd k8s-infrastructure/monitoring
./setup-grafana-persistence.sh
```

---

## Files Created

### Configuration Files
```
k8s-infrastructure/monitoring/
├── README.md                          # Comprehensive documentation
├── grafana-pvc.yaml                   # Grafana PersistentVolumeClaim
├── prometheus-values.yaml             # Helm values with persistence
├── setup-grafana-persistence.sh       # Automated setup script
└── quick-fix-grafana.sh               # One-command fix script
```

### Modified Files
```
scripts/
└── startup-cluster.sh                 # Added Step 8.5 for Grafana persistence
```

---

## Troubleshooting

### Issue 1: PVC Stuck in Pending
**Symptoms:** PVC shows `Pending` status indefinitely

**Diagnosis:**
```bash
kubectl describe pvc prometheus-grafana -n monitoring
```

**Common Causes:**
1. EBS CSI driver not installed (required for EKS 1.23+)
2. No available storage in the cluster
3. StorageClass `gp2` doesn't exist

**Solution:**
```bash
# Check StorageClass
kubectl get storageclass

# If missing, create gp2 StorageClass
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2
provisioner: ebs.csi.aws.com
parameters:
  type: gp2
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
EOF
```

### Issue 2: Grafana Pod Won't Start
**Symptoms:** Pod in `CrashLoopBackOff` or `Pending`

**Diagnosis:**
```bash
kubectl describe pod -n monitoring -l app.kubernetes.io/name=grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

**Common Causes:**
1. Volume mount permissions issue
2. PVC not bound
3. Insufficient resources

**Solution:**
```bash
# Check PVC status
kubectl get pvc -n monitoring

# If PVC is bound but pod won't start, check events
kubectl get events -n monitoring --sort-by='.lastTimestamp'

# Restart deployment
kubectl rollout restart deployment/prometheus-grafana -n monitoring
```

### Issue 3: Dashboards Still Not Persisting
**Symptoms:** Imported dashboards disappear after restart

**Diagnosis:**
```bash
# Verify volume is actually mounted
kubectl exec -n monitoring deployment/prometheus-grafana -- df -h | grep grafana

# Check storage path
kubectl exec -n monitoring deployment/prometheus-grafana -- ls -la /var/lib/grafana
```

**Solution:**
```bash
# Ensure PVC is correctly referenced in deployment
kubectl get deployment prometheus-grafana -n monitoring -o yaml | grep -A 10 "volumes:"

# Should show volume with PVC claim name
# If not, re-run setup script
cd k8s-infrastructure/monitoring
./setup-grafana-persistence.sh
```

### Issue 4: High Cost from Storage
**Symptoms:** Unexpected AWS bill increase

**Solution Options:**

**Option 1: Reduce Retention**
```yaml
# In prometheus-values.yaml
prometheus:
  prometheusSpec:
    retention: 7d  # Reduce from 15d to 7d
```

**Option 2: Reduce Storage Size**
```yaml
# In prometheus-values.yaml
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 10Gi  # Reduce from 20Gi
```

**Option 3: Use gp3 (Cheaper)**
```yaml
storageClassName: gp3  # $0.08/GB vs $0.10/GB for gp2
```

---

## Best Practices

### 1. Regular Backups
Even with persistent storage, create backups:

```bash
# Export Grafana dashboards
kubectl exec -n monitoring deployment/prometheus-grafana -- \
    grafana-cli admin export-dashboard > grafana-backup.json

# Save to S3
aws s3 cp grafana-backup.json s3://your-backup-bucket/grafana/$(date +%Y%m%d)/
```

### 2. Snapshot Volumes
Create EBS snapshots for disaster recovery:

```bash
# Get volume IDs
VOLUME_IDS=$(kubectl get pvc -n monitoring -o json | \
    jq -r '.items[].spec.volumeName' | \
    xargs -I {} kubectl get pv {} -o jsonpath='{.spec.awsElasticBlockStore.volumeID}' | \
    cut -d'/' -f4)

# Create snapshots
for vol in $VOLUME_IDS; do
    aws ec2 create-snapshot --volume-id "$vol" \
        --description "Grafana backup $(date +%Y-%m-%d)" \
        --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=grafana-backup}]"
done
```

### 3. Monitor Disk Usage
Set up alerts for when storage is running out:

```promql
# Prometheus alert for Grafana disk usage > 80%
kubelet_volume_stats_used_bytes{persistentvolumeclaim="prometheus-grafana"} / 
kubelet_volume_stats_capacity_bytes{persistentvolumeclaim="prometheus-grafana"} > 0.8
```

### 4. Version Control Dashboards
Export and commit dashboards to Git:

```bash
# Export all dashboards
./scripts/export-grafana-dashboards.sh

# Commit to repo
git add grafana-dashboards/
git commit -m "chore: backup Grafana dashboards"
git push
```

---

## Rollback Plan

If the fix causes issues, rollback to previous state:

### 1. Uninstall with Persistence
```bash
helm uninstall prometheus -n monitoring
```

### 2. Reinstall without Persistence
```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring
```

### 3. Delete PVCs (Optional)
```bash
kubectl delete pvc --all -n monitoring
```

**Note:** This will delete all stored data permanently.

---

## Success Metrics

### Before Fix
- ❌ Dashboards lost on every pod restart
- ❌ Manual dashboard recreation required
- ❌ No metrics data retention
- ❌ 30+ minutes to reconfigure Grafana

### After Fix
- ✅ Dashboards persist across restarts
- ✅ Zero manual intervention needed
- ✅ 15 days of metrics retained
- ✅ < 5 minutes recovery time
- ✅ $3.50/month storage cost

---

## Future Enhancements

### 1. Automated Dashboard Provisioning
Create `ConfigMap` with dashboard JSONs:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: monitoring
data:
  kubernetes-cluster.json: |
    { ... dashboard JSON ... }
```

### 2. S3 Backup Integration
Automated daily backups to S3:
```bash
# Cron job to backup Grafana data
0 2 * * * /usr/local/bin/backup-grafana-to-s3.sh
```

### 3. Multi-Region Replication
For disaster recovery, replicate snapshots:
```bash
aws ec2 copy-snapshot \
    --source-region us-east-1 \
    --source-snapshot-id snap-abc123 \
    --destination-region us-west-2
```

---

## References

- [Prometheus Operator](https://prometheus-operator.dev/)
- [Grafana Persistent Storage](https://grafana.com/docs/grafana/latest/setup-grafana/configure-docker/)
- [Kubernetes PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [AWS EBS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html)
- [Helm kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

---

## Changelog

### November 27, 2025 - Initial Fix
- ✅ Created PersistentVolumeClaim configurations
- ✅ Created Helm values with persistence enabled
- ✅ Created automated setup script
- ✅ Integrated into startup script (Step 8.5)
- ✅ Documented troubleshooting steps
- ✅ Tested persistence across pod restarts

### Next Steps
- [ ] Add automated dashboard provisioning via ConfigMap
- [ ] Set up daily S3 backups
- [ ] Configure disk usage alerts
- [ ] Document dashboard version control workflow
