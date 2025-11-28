# Monitoring Ingress Deployment Guide

## Overview

This guide documents the implementation of **shared ALB architecture** for monitoring access (Grafana and Prometheus) in the EKS cluster. This approach provides stable external access while minimizing infrastructure costs.

## 🎯 Architectural Decision

**Selected Approach:** Shared ALB with Path-Based Routing  
**Cost Impact:** $0 additional (reuses existing application ALB)  
**Access Pattern:** 
- `https://monitoring.tarang.cloud/grafana` → Grafana Dashboard
- `https://monitoring.tarang.cloud/prometheus` → Prometheus Query UI

## ⚠️ Architectural Limitations & Trade-offs

### Critical Limitations

1. **Monitoring Availability Tied to EKS Cluster Health**
   - If the EKS cluster experiences failures (control plane issues, all nodes down, etc.), monitoring goes down with the application
   - **Impact:** No independent observability during cluster outages
   - **Risk Level:** Medium for small-scale applications, HIGH for production systems

2. **Cannot Outlive Application Failures**
   - Monitoring pods run in the same cluster as application pods
   - During cluster maintenance windows, monitoring is unavailable
   - Cannot monitor cluster-level issues (e.g., node exhaustion, API server problems)
   - **Impact:** Blind spots during critical failure scenarios

3. **Not Suitable for Multi-Cluster Monitoring**
   - This setup only monitors the single cluster it runs in
   - Cannot aggregate metrics from dev/staging/prod environments
   - **Impact:** Limited for organizations with multiple clusters

### When This Architecture is Appropriate

✅ **Good fit for:**
- Small to medium applications (<100k requests/day)
- Single-cluster deployments
- Cost-conscious projects in early stages
- Development/staging environments
- Applications with external monitoring backup (e.g., CloudWatch alarms)

❌ **NOT suitable for:**
- Production systems requiring 24/7 observability
- Applications with strict SLAs (e.g., 99.9%+ uptime requirements)
- Multi-cluster environments (dev/staging/prod)
- Organizations with compliance requirements for isolated monitoring
- Systems where monitoring must survive application outages

## 📈 Future Migration Path

### When to Migrate to Separate Monitoring Infrastructure

**Triggers for migration:**
1. Application traffic exceeds 100,000 requests/day
2. Need monitoring during cluster maintenance windows
3. Deploying multiple clusters (dev/staging/prod)
4. Compliance requirements mandate isolated monitoring
5. Budget allows for dedicated infrastructure ($40-100/month)
6. Experiencing frequent cluster-level issues requiring external visibility

### Migration Strategy Options

#### Option 1: Separate EKS/EC2 Monitoring Cluster (Recommended for Medium Scale)

**Architecture:**
```
Production EKS Cluster
  └─> Prometheus Remote Write
        └─> Separate Monitoring Cluster (External EKS/EC2)
              ├─> Prometheus (receives metrics)
              ├─> Grafana (dashboards)
              └─> Separate ALB/NLB
```

**Cost:** ~$40-60/month (t3.small EC2 + ALB)  
**Benefits:**
- Full operational independence
- Monitoring survives application cluster failures
- Can monitor multiple clusters
- Complete control over infrastructure

**Implementation Steps:**
1. Provision separate monitoring infrastructure (EC2 or small EKS cluster)
2. Configure Prometheus Remote Write in current cluster:
   ```yaml
   remoteWrite:
   - url: "https://monitoring-cluster.tarang.cloud/api/v1/write"
   ```
3. Run dual-stack for validation period (1-2 weeks)
4. Update DNS to point to external monitoring
5. Decommission in-cluster monitoring

#### Option 2: AWS Managed Services (AMP + AMG) (Recommended for Enterprise)

**Architecture:**
```
Production EKS Cluster
  └─> AWS Managed Prometheus (AMP)
        └─> AWS Managed Grafana (AMG)
```

**Cost:** ~$60-100/month  
**Benefits:**
- Fully managed, no operational overhead
- Auto-scaling, high availability built-in
- AWS-native integrations
- Multi-region support

**Implementation Steps:**
1. Create AMP workspace
2. Create AMG workspace
3. Configure Prometheus Remote Write to AMP
4. Connect AMG to AMP datasource
5. Migrate dashboards to AMG
6. Decommission in-cluster monitoring

#### Option 3: Hybrid Approach (Best of Both Worlds)

**Architecture:**
```
In-Cluster Prometheus (short retention, fast queries)
  └─> Remote Write to External Long-Term Storage
        └─> External Grafana (queries both sources)
```

**Cost:** ~$40-80/month  
**Benefits:**
- Fast queries for recent data (in-cluster)
- Long-term retention externally
- Monitoring survives cluster failures for historical analysis
- Gradual migration path

## 🚀 Deployment Instructions

### Prerequisites

1. **AWS Load Balancer Controller installed** in the EKS cluster
   ```bash
   kubectl get deployment -n kube-system aws-load-balancer-controller
   ```

2. **ACM Certificate** for `monitoring.tarang.cloud`
   ```bash
   aws acm request-certificate \
     --domain-name monitoring.tarang.cloud \
     --validation-method DNS \
     --region us-east-1
   ```

3. **Route53 Hosted Zone** for `tarang.cloud` domain

### Step 1: Update Existing Application Ingress

The existing `k8s-infrastructure/ingress.yaml` has been updated with ALB group annotations:

```yaml
metadata:
  annotations:
    alb.ingress.kubernetes.io/group.name: shared-alb  # ← Enables ALB sharing
    alb.ingress.kubernetes.io/group.order: '10'       # ← App has priority
```

**Apply the updated Ingress:**
```bash
kubectl apply -f k8s-infrastructure/ingress.yaml
```

### Step 2: Update Prometheus Helm Values

The `prometheus-values.yaml` has been updated to:
- Change services from `NodePort` to `ClusterIP`
- Configure Grafana for subpath deployment (`/grafana`)

**Upgrade the Helm release:**
```bash
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values k8s-infrastructure/monitoring/prometheus-values.yaml
```

### Step 3: Create Monitoring Ingress

**Update the ACM certificate ARN** in `monitoring-ingress.yaml`:
```yaml
alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:296062548155:certificate/YOUR-CERT-ARN
```

**Apply the monitoring Ingress:**
```bash
kubectl apply -f k8s-infrastructure/monitoring/monitoring-ingress.yaml
```

### Step 4: Get ALB DNS Name

```bash
kubectl get ingress -n three-tier mainlb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Example output: `k8s-sharedalb-1234567890.us-east-1.elb.amazonaws.com`

### Step 5: Configure Route53 DNS

Create **CNAME records** pointing to the ALB:

```bash
# Get the ALB DNS name
ALB_DNS=$(kubectl get ingress -n three-tier mainlb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Create Route53 record for monitoring domain
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_HOSTED_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "monitoring.tarang.cloud",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "'"$ALB_DNS"'"}]
      }
    }]
  }'
```

### Step 6: Verify Deployment

**Check Ingress resources:**
```bash
# Application Ingress
kubectl get ingress -n three-tier mainlb

# Monitoring Ingress
kubectl get ingress -n monitoring monitoring-ingress
```

**Both should show the SAME ALB address** (shared-alb group)

**Access monitoring:**
- Grafana: `https://monitoring.tarang.cloud/grafana`
- Prometheus: `https://monitoring.tarang.cloud/prometheus`

**Default Grafana credentials:**
- Username: `admin`
- Password: `admin` (configured in `prometheus-values.yaml` - **change in production!**)

### Step 7: Configure Grafana Datasource

After deployment, Grafana needs to be configured to query Prometheus.

**Access Grafana:**
```bash
# Open browser to Grafana
open https://monitoring.tarang.cloud/grafana

# Login with credentials: admin / admin
```

**Add Prometheus Datasource:**
1. Navigate to **Configuration** (⚙️ gear icon) → **Data Sources**
2. Click **"Add data source"**
3. Select **"Prometheus"**
4. Configure:
   - **Name:** `Prometheus`
   - **URL:** `http://prometheus-kube-prometheus-prometheus:9090/prometheus`
     - ⚠️ Use internal ClusterIP service URL (not external Ingress)
     - Include `/prometheus` suffix because of `routePrefix` configuration
   - **Access:** `Server` (Grafana accesses Prometheus within cluster)
   - **Auth:** No authentication
   - **TLS:** Skip TLS certificate verification
5. Click **"Save & Test"**
6. Verify: Should show **"✅ Data source is working"**

**Test datasource connectivity (optional):**
```bash
# From Grafana pod, test Prometheus API
kubectl -n monitoring exec -it deploy/prometheus-grafana -- \
  curl -s http://prometheus-kube-prometheus-prometheus:9090/prometheus/api/v1/status/buildinfo | jq
```

Expected: JSON response with Prometheus version

**Import Kubernetes dashboards:**
1. Click **"+"** → **Import**
2. Enter dashboard ID: **315** (Kubernetes cluster monitoring)
3. Select **Prometheus** datasource
4. Click **Import**

**Or import from file:**
- Path: `assets/grafana_dashboard/Kubernetes cluster monitoring (via Prometheus)-1764256820704.json`
- Method: **+ → Import → Upload JSON file**

## 🔍 Validation & Troubleshooting

### Verify ALB Sharing

Both Ingresses should reference the same ALB:

```bash
kubectl get ingress -A -o json | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name): \(.status.loadBalancer.ingress[0].hostname)"'
```

Expected output:
```
three-tier/mainlb: k8s-sharedalb-1234567890.us-east-1.elb.amazonaws.com
monitoring/monitoring-ingress: k8s-sharedalb-1234567890.us-east-1.elb.amazonaws.com
```

### Common Issues

**1. Grafana shows "404 Not Found" or "Too Many Redirects"**

**Cause:** Grafana not configured for subpath deployment  
**Solution:** Verify `grafana.ini` configuration in `prometheus-values.yaml`:
```yaml
grafana:
  grafana.ini:
    server:
      root_url: https://monitoring.tarang.cloud/grafana
      serve_from_sub_path: true
```

Re-upgrade Helm chart if needed.

**2. Separate ALBs Created Instead of Shared**

**Cause:** `group.name` mismatch or missing  
**Solution:** Verify both Ingresses have identical `alb.ingress.kubernetes.io/group.name` annotations:
```bash
kubectl get ingress -A -o yaml | grep "group.name"
```

**3. Certificate Validation Pending**

**Cause:** DNS validation not completed  
**Solution:** 
```bash
# Get validation records
aws acm describe-certificate --certificate-arn YOUR_CERT_ARN --region us-east-1

# Add CNAME records to Route53 for validation
```

**4. "Cannot reach Prometheus/Grafana"**

**Debugging steps:**
```bash
# Check pod status
kubectl get pods -n monitoring

# Check service endpoints
kubectl get svc -n monitoring

# Check Ingress events
kubectl describe ingress monitoring-ingress -n monitoring

# Check ALB target health in AWS Console
# EC2 → Load Balancers → Target Groups → Health Status
```

**5. Grafana Datasource Shows "404 Not Found" Error**

**Cause:** Incorrect Prometheus URL or missing routePrefix configuration  
**Symptoms:** Grafana datasource test fails with "404 Not Found - There was an error returned querying the Prometheus API"

**Solution:**
1. **Verify Prometheus routePrefix configuration** in `prometheus-values.yaml`:
   ```yaml
   prometheus:
     prometheusSpec:
       externalUrl: https://monitoring.tarang.cloud/prometheus
       routePrefix: /prometheus  # ← Must be set for subpath deployment
   ```

2. **Update Grafana datasource URL** to include the routePrefix:
   - Correct: `http://prometheus-kube-prometheus-prometheus:9090/prometheus`
   - Incorrect: `http://prometheus-kube-prometheus-prometheus:9090` (missing `/prometheus` suffix)

3. **Test connectivity from Grafana pod:**
   ```bash
   kubectl -n monitoring exec -it deploy/prometheus-grafana -- \
     curl -s http://prometheus-kube-prometheus-prometheus:9090/prometheus/api/v1/status/buildinfo
   ```
   Expected: JSON response with `"status":"success"`

4. **If still failing, check service names:**
   ```bash
   # Verify actual Prometheus service name (depends on Helm release name)
   kubectl get svc -n monitoring | grep prometheus
   
   # If release name is "prometheus", service is: prometheus-kube-prometheus-prometheus
   # If release name is different, adjust datasource URL accordingly
   ```

**Alternative (if you prefer root path):**
- Remove `routePrefix` from prometheus-values.yaml
- Upgrade Helm: `helm upgrade prometheus ... --values prometheus-values.yaml`
- Update Grafana datasource to: `http://prometheus-kube-prometheus-prometheus:9090`
- Note: External Prometheus URL will still work via Ingress path routing

## 📊 Cost Summary

| Component | Monthly Cost | Notes |
|-----------|--------------|-------|
| **Existing ALB** | ~$16 | Already provisioned for application |
| **Monitoring Ingress** | $0 | Shares existing ALB (group: shared-alb) |
| **EBS Volumes** | ~$3 | Prometheus (20Gi) + Grafana (10Gi) + AlertManager (5Gi) |
| **Data Transfer** | ~$1-5 | Depends on monitoring query volume |
| **Total Additional Cost** | **~$3-5/month** | Just storage, no new load balancers |

**Cost avoided:** ~$32/month (2 separate NLBs @ $16 each)

## 📝 Operational Notes

### External Health Monitoring

Monitor the monitoring stack externally using CloudWatch or uptime services:
```bash
# Monitor endpoint
https://monitoring.tarang.cloud/grafana/api/health
```

### Backup

**Grafana dashboards:** Stored in persistent 10Gi EBS volume  
**Prometheus data:** Stored in persistent 20Gi EBS volume (15 days retention)

### Helm Upgrades

```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values k8s-infrastructure/monitoring/prometheus-values.yaml
```

---

**Document Version:** 2.0  
**Last Updated:** November 28, 2025  
**Review:** Quarterly or when traffic exceeds 50k requests/day

## 📝 Change Log

### Version 2.0 - November 28, 2025
- Deployed shared ALB architecture with path-based routing
- Converted services from NodePort to ClusterIP
- Configured subpath routing for Grafana (`/grafana`) and Prometheus (`/prometheus`)
- Set up DNS: `monitoring.tarang.cloud` → ALB
- Configured Grafana datasource with internal service URL
- Cost savings: $32/month (avoided 2 NLBs)

### Version 1.0 - November 2025
- Initial deployment guide with architectural decisions

