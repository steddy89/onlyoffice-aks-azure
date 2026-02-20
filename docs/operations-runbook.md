# Operations Runbook

## ONLYOFFICE Document Server - Day 2 Operations

### Table of Contents
1. [Common Operations](#common-operations)
2. [Scaling](#scaling)
3. [Upgrading](#upgrading)
4. [Troubleshooting](#troubleshooting)
5. [Monitoring Queries](#monitoring-queries)

---

### Common Operations

#### Access the AKS Cluster
```bash
# Login to Azure
az login

# Get AKS credentials
az aks get-credentials \
  --resource-group rg-onlyoffice-prod \
  --name aks-onlyoffice-prod \
  --overwrite-existing

# Verify access
kubectl get nodes
kubectl get pods -n onlyoffice
```

#### View Pod Logs
```bash
# All pods
kubectl logs -n onlyoffice -l app.kubernetes.io/name=onlyoffice-docserver --tail=100

# Specific pod
kubectl logs -n onlyoffice <pod-name> -f

# Previous container (after crash)
kubectl logs -n onlyoffice <pod-name> --previous
```

#### Restart ONLYOFFICE Pods (Rolling)
```bash
kubectl rollout restart deployment -n onlyoffice onlyoffice-docserver
kubectl rollout status deployment -n onlyoffice onlyoffice-docserver
```

#### Check Health Status
```bash
# Pod health
kubectl get pods -n onlyoffice -o wide

# Health endpoint (from within cluster)
kubectl run curl --image=curlimages/curl -i --rm --restart=Never -- \
  curl -s http://onlyoffice-docserver.onlyoffice.svc.cluster.local/healthcheck
```

---

### Scaling

#### Manual Scale
```bash
# Scale pods
kubectl scale deployment onlyoffice-docserver -n onlyoffice --replicas=5

# Scale node pool
az aks nodepool scale \
  --resource-group rg-onlyoffice-prod \
  --cluster-name aks-onlyoffice-prod \
  --name onlyoffice \
  --node-count 5
```

#### Check Autoscaler Status
```bash
# HPA status
kubectl get hpa -n onlyoffice

# Cluster autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler --tail=50
```

---

### Upgrading

#### Upgrade ONLYOFFICE Version
1. Update `image.tag` in `kubernetes/helm/onlyoffice-docserver/values.yaml`
2. Commit and push to trigger CI/CD
3. Or manually:
```bash
helm upgrade onlyoffice-docserver \
  kubernetes/helm/onlyoffice-docserver \
  --namespace onlyoffice \
  --set image.tag=8.2 \
  --wait --timeout 10m
```

#### Upgrade AKS Kubernetes Version
```bash
# Check available versions
az aks get-upgrades \
  --resource-group rg-onlyoffice-prod \
  --name aks-onlyoffice-prod \
  --output table

# Upgrade (update terraform variable, then apply)
# In terraform/environments/prod.tfvars:
# kubernetes_version = "1.30"
terraform plan -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

---

### Troubleshooting

#### Pod in CrashLoopBackOff
```bash
# Check events
kubectl describe pod <pod-name> -n onlyoffice

# Check logs
kubectl logs <pod-name> -n onlyoffice --previous

# Common causes:
# 1. Database connection failure → check PostgreSQL connectivity
# 2. Redis connection failure → check Redis connectivity  
# 3. Storage mount failure → check Azure Files PVC
# 4. JWT secret misconfiguration → check Kubernetes secret
```

#### Database Connection Issues
```bash
# Test from AKS pod
kubectl run psql-test --image=postgres:15 -i --rm --restart=Never -- \
  psql "host=<postgresql-fqdn> port=5432 dbname=onlyoffice user=onlyoffice_admin sslmode=require" \
  -c "SELECT 1;"

# Check DNS resolution
kubectl run dns-test --image=busybox:1.36 -i --rm --restart=Never -- \
  nslookup <postgresql-fqdn>
```

#### Storage Issues
```bash
# Check PVC status
kubectl get pvc -n onlyoffice

# Check PV status
kubectl get pv | grep onlyoffice

# Describe PVC for events
kubectl describe pvc onlyoffice-data -n onlyoffice
```

#### Ingress/SSL Issues
```bash
# Check ingress
kubectl get ingress -n onlyoffice
kubectl describe ingress -n onlyoffice

# Check Application Gateway health
az network application-gateway show-backend-health \
  --resource-group <MC_resource_group> \
  --name <appgw-name> \
  --query 'backendAddressPools[].backendHttpSettingsCollection[].servers[]' \
  --output table
```

---

### Monitoring Queries

#### KQL Queries for Log Analytics

**Error rate over time:**
```kql
ContainerLog
| where LogEntry contains "error" and Namespace_s == "onlyoffice"
| summarize ErrorCount = count() by bin(TimeGenerated, 5m)
| render timechart
```

**Pod restart history:**
```kql
KubePodInventory
| where Namespace == "onlyoffice"
| where ContainerRestartCount > 0
| project TimeGenerated, Name, ContainerRestartCount
| order by TimeGenerated desc
```

**Resource utilization:**
```kql
Perf
| where ObjectName == "K8SContainer"
| where InstanceName contains "onlyoffice"
| where CounterName in ("cpuUsageNanoCores", "memoryWorkingSetBytes")
| summarize avg(CounterValue) by CounterName, bin(TimeGenerated, 5m)
| render timechart
```

**Active document sessions:**
```kql
ContainerLog
| where Namespace_s == "onlyoffice"
| where LogEntry contains "session"
| summarize Sessions = dcount(extract("sessionId[=:]\\s*([a-zA-Z0-9-]+)", 1, LogEntry)) by bin(TimeGenerated, 5m)
| render timechart
```
