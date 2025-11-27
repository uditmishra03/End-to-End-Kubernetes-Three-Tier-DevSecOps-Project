# Migration Guide: Default Namespace → Monitoring Namespace

## Overview

This guide helps you safely migrate from the old Grafana/Prometheus setup (in `default` namespace) to the new persistent storage setup (in `monitoring` namespace).

---

## Current State

### Old Setup (default namespace)
```
Namespace: default
├── stable-grafana (LoadBalancer)
├── stable-kube-prometheus-sta-prometheus (LoadBalancer)
└── No persistent storage ❌
```

**Access URLs:**
- Grafana: `http://a2c6af4284b0a492ca5361c0f803d6d2-1545715117.us-east-1.elb.amazonaws.com`
- Prometheus: `http://aba486402dcc7489db934c692c09b53f-468856416.us-east-1.elb.amazonaws.com:9090`

### New Setup (monitoring namespace)
```
Namespace: monitoring
├── prometheus-grafana (NodePort 32000)
├── prometheus-kube-prometheus-prometheus (NodePort 32090)
└── With persistent storage ✅
    ├── Grafana: 10Gi EBS volume
    ├── Prometheus: 20Gi EBS volume
    └── AlertManager: 5Gi EBS volume
```

---

## Migration Steps

### Phase 1: Install New Stack (No Downtime)

#### Step 1: Install/Upgrade via Helm
```bash
cd k8s-infrastructure/monitoring

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring -f prometheus-values.yaml
```

**Expected Output:**
```
========================================
  Grafana Persistent Storage Setup
========================================

Note: This will install a new Prometheus/Grafana stack in the 'monitoring' namespace.
Your existing setup in 'default' namespace will NOT be touched.

>>> Step 1: Checking monitoring namespace
✓ Namespace 'monitoring' created

>>> Step 2: Checking existing installation in monitoring namespace
⚠ No existing Helm release found in monitoring namespace.
Will perform fresh install (existing setup in 'default' namespace will not be touched)

>>> Step 3: Updating Helm repository
✓ Helm repository updated

>>> Step 4: Configuring persistent storage for Grafana and Prometheus
Installing Prometheus stack with persistent storage...
✓ Helm release installed successfully

>>> Step 5: Verifying PersistentVolumeClaims
✓ Grafana PVC created
✓ Prometheus PVC created

>>> Step 6: Waiting for Grafana pod to be ready
✓ Grafana pod is ready

>>> Step 7: Access Information
========================================
  Configuration Complete!
========================================

Grafana Dashboard:
  URL: http://<NEW-LOADBALANCER-URL>
  Username: admin
  Password: <PASSWORD>

Prometheus Dashboard:
  URL: http://<NEW-PROMETHEUS-URL>:9090
```

#### Step 2: Verify Installation
```bash
# Check namespace
kubectl get namespace monitoring

# Check pods
kubectl get pods -n monitoring

# Check PVCs
kubectl get pvc -n monitoring

# Check services
kubectl get svc -n monitoring
```

**Expected:**
```
NAME                                                READY   STATUS    RESTARTS   AGE
prometheus-grafana-xxxxx                            3/3     Running   0          2m
prometheus-kube-prometheus-prometheus-0             2/2     Running   0          2m
prometheus-kube-state-metrics-xxxxx                 1/1     Running   0          2m
prometheus-prometheus-node-exporter-xxxxx           1/1     Running   0          2m
```

#### Step 3: Get New Access URLs
```bash
# Get node external IPs
kubectl get nodes -o wide

# Get admin password
kubectl get secret prometheus-grafana -n monitoring \
    -o jsonpath="{.data.admin-password}" | base64 -d
echo
```

**Access URLs:**
- Grafana: `http://<NODE-EXTERNAL-IP>:32000`
- Prometheus: `http://<NODE-EXTERNAL-IP>:32090`

---

### Phase 2: Test New Setup

#### Step 1: Access New Grafana
```bash
# Open browser to: http://<NODE-EXTERNAL-IP>:32000
# Login: admin / <password from above>
```

#### Step 2: Configure Prometheus Datasource
1. Go to **Configuration** → **Data Sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Configure:
   - Name: `Prometheus`
  - URL: `http://prometheus-operated:9090`
   - Access: `Server (default)`
5. Click **Save & Test**

Should show: ✅ "Data source is working"

#### Step 3: Import Dashboards
Import these popular Kubernetes dashboards:

```bash
# Dashboard IDs to import:
15760 - Kubernetes / Views / Global
15761 - Kubernetes / Views / Namespaces  
15762 - Kubernetes / Views / Pods
6417  - Kubernetes Cluster Monitoring
13770 - Kubernetes Cluster (Prometheus)
```

**Import Steps:**
1. Click **"+" → Import**
2. Enter Dashboard ID
3. Click **Load**
4. Select **Prometheus** datasource
5. Click **Import**

#### Step 4: Verify Persistence
Test that dashboards survive restarts:

```bash
# Restart Grafana pod
kubectl rollout restart deployment/prometheus-grafana -n monitoring

# Wait for pod to be ready
kubectl wait --for=condition=available --timeout=300s \
    deployment/prometheus-grafana -n monitoring

# Access Grafana again - dashboards should still be there!
```

---

### Phase 3: Side-by-Side Comparison

Run both systems in parallel for testing:

| Feature | Old (default) | New (monitoring) |
|---------|--------------|------------------|
| **Namespace** | `default` | `monitoring` |
| **Persistent Storage** | ❌ No | ✅ Yes (35Gi total) |
| **Dashboard Retention** | ❌ Lost on restart | ✅ Persists forever |
| **Metrics Retention** | Unknown | ✅ 15 days |
| **Cost** | Free (no storage) | ~$3.50/month |

### Notes
- The EKS node group was scaled from 2 → 3 nodes to ensure adequate capacity for the monitoring stack (Prometheus Operator, Grafana, AlertManager) and persistent volumes.
- Legacy `default` namespace releases should be uninstalled after validation:
  ```bash
  helm uninstall grafana -n default || true
  helm uninstall prometheus -n default || true
  ```

#### Comparison Checklist

- [ ] New Grafana accessible
- [ ] Prometheus datasource configured
- [ ] Dashboards imported
- [ ] Metrics data appearing
- [ ] Persistence verified (pod restart test)
- [ ] Performance acceptable
- [ ] No errors in logs

#### Check Logs
```bash
# Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=50

# Prometheus logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus --tail=50
```

---

### Phase 4: Cleanup Old Setup (After Verification)

⚠️ **IMPORTANT:** Only proceed after confirming new setup works perfectly!

#### Option 1: Automated Cleanup Script
```bash
cd k8s-infrastructure/monitoring
chmod +x cleanup-old-monitoring.sh
./cleanup-old-monitoring.sh
```

The script will:
1. List all Helm releases in `default` namespace
2. Prompt for confirmation before each deletion
3. Remove standalone resources (if not Helm-managed)
4. Show summary of remaining resources

#### Option 2: Manual Cleanup

##### Find Helm Releases
```bash
helm list -n default
```

##### Uninstall Old Monitoring Stack
```bash
# Replace <release-name> with actual name from above
helm uninstall <release-name> -n default

# Example:
# helm uninstall stable -n default
```

##### Verify Removal
```bash
# Should show no monitoring pods
kubectl get pods -n default | grep -E "grafana|prometheus"

# Should show no monitoring services
kubectl get svc -n default | grep -E "grafana|prometheus"
```

---

## Rollback Plan

If new setup has issues, you can rollback:

### Step 1: Remove New Installation
```bash
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

### Step 2: Keep Using Old Setup
Your old setup in `default` namespace remains untouched.

### Step 3: Troubleshoot
Check the troubleshooting section in `GRAFANA-PERSISTENCE-FIX.md`

---

## Post-Migration Checklist

- [ ] Old Grafana/Prometheus removed from `default` namespace
- [ ] New stack running in `monitoring` namespace
- [ ] All dashboards reconfigured and working
- [ ] Persistence verified (tested pod restart)
- [ ] New URLs documented/shared with team
- [ ] Old LoadBalancer URLs no longer in use
- [ ] Monitoring costs reviewed (~$3.50/month for storage)
- [ ] Backup strategy in place (optional)

---

## URL Updates

### Update Your Documentation
After migration, update these references:

**Old URLs (will stop working after cleanup):**
```
Grafana:    http://a2c6af4284b0a492ca5361c0f803d6d2-1545715117.us-east-1.elb.amazonaws.com
Prometheus: http://aba486402dcc7489db934c692c09b53f-468856416.us-east-1.elb.amazonaws.com:9090
```

**New URLs:**
```bash
# Get new URLs with:
kubectl get svc -n monitoring | grep -E "grafana|prometheus"
```

---

## Namespace Comparison

```bash
# View both namespaces side by side
echo "=== OLD SETUP (default) ==="
kubectl get pods,svc -n default | grep -E "grafana|prometheus"

echo ""
echo "=== NEW SETUP (monitoring) ==="
kubectl get pods,svc,pvc -n monitoring
```

---

## Cost Impact

### Before Migration
- Storage: $0/month
- Risk: High (data loss on every restart)

### After Migration  
- Storage: ~$3.50/month
  - Grafana: 10Gi × $0.10 = $1.00/month
  - Prometheus: 20Gi × $0.10 = $2.00/month
  - AlertManager: 5Gi × $0.10 = $0.50/month
- Risk: Low (persistent data)

---

## FAQ

### Q: Can I run both setups simultaneously?
**A:** Yes! They're in different namespaces. The new one won't affect the old one.

### Q: Will my old Grafana dashboards be copied automatically?
**A:** No, you need to manually reconfigure/import dashboards in the new Grafana. This is why we keep the old one running during migration.

### Q: What if I forget the new Grafana password?
**A:** Retrieve it anytime:
```bash
kubectl get secret prometheus-grafana -n monitoring \
    -o jsonpath="{.data.admin-password}" | base64 -d; echo
```

### Q: Can I change back to `default` namespace later?
**A:** Yes, but not recommended. Best practice is to keep monitoring tools in a dedicated namespace.

### Q: What happens to my old LoadBalancers?
**A:** They'll be deleted when you remove the old setup. New LoadBalancers will be created in the `monitoring` namespace.

---

## Next Steps After Migration

1. **Set up automated backups** (optional)
   ```bash
   # Export dashboards regularly
   kubectl exec -n monitoring deployment/prometheus-grafana -- \
       grafana-cli admin export-dashboard > backup.json
   ```

2. **Configure alerts** (optional)
   - Set up disk usage alerts for PVCs
   - Configure Slack/email notifications

3. **Document new URLs**
   - Update README.md
   - Update DOCUMENTATION.md
   - Share with team

4. **Monitor costs**
   - Check AWS billing for EBS volumes
   - Adjust retention/size if needed

---

## Support

If you encounter issues during migration:

1. Check logs: `kubectl logs -n monitoring <pod-name>`
2. Review troubleshooting: `docs/fixes/GRAFANA-PERSISTENCE-FIX.md`
3. Compare with old setup: `kubectl get all -n default`
4. Rollback if needed (see Rollback Plan above)
