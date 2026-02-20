# Backup & Disaster Recovery Strategy

## ONLYOFFICE Document Server on Azure AKS

### Recovery Objectives

| Metric | Target | Notes |
|--------|--------|-------|
| **RPO** (Recovery Point Objective) | 1 hour | Maximum acceptable data loss |
| **RTO** (Recovery Time Objective) | 4 hours | Maximum acceptable downtime |
| **MTTR** (Mean Time To Recovery) | 2 hours | Average recovery time |

---

### 1. Backup Strategy

#### 1.1 PostgreSQL Database

| Aspect | Configuration |
|--------|--------------|
| Backup Type | Automated + Point-in-Time Restore |
| Retention | 35 days |
| Geo-redundant | Yes (production) |
| Frequency | Continuous (WAL-based) |
| PITR Granularity | Any point within retention |

**Automated Backups** (Terraform-managed):
```hcl
backup_retention_days        = 35
geo_redundant_backup_enabled = true  # prod only
```

**Manual Backup Procedure**:
```bash
# Export database
az postgres flexible-server execute \
  --name psql-onlyoffice-prod-XXXXXXXX \
  --resource-group rg-onlyoffice-prod \
  --admin-user onlyoffice_admin \
  --admin-password "$(az keyvault secret show --vault-name kv-onlyoffice-prod --name postgresql-admin-password --query value -o tsv)" \
  --querytext "SELECT pg_dump('onlyoffice')" \
  --output table
```

**Point-in-Time Restore**:
```bash
az postgres flexible-server restore \
  --resource-group rg-onlyoffice-prod \
  --name psql-onlyoffice-prod-restored \
  --source-server psql-onlyoffice-prod-XXXXXXXX \
  --restore-time "2026-02-20T10:00:00Z"
```

#### 1.2 Redis Cache

| Aspect | Configuration |
|--------|--------------|
| Backup Type | RDB snapshots (Premium SKU) |
| Frequency | Every 60 minutes |
| Retention | 1 snapshot |
| Storage | Azure Blob Storage |

**Note**: Redis is used as a session/coordination cache. Data loss is tolerable — sessions will be re-established automatically.

#### 1.3 Document Storage (Azure Files)

| Aspect | Configuration |
|--------|--------------|
| Backup Type | Azure File Share snapshots |
| Replication | ZRS (Zone-redundant) |
| Soft Delete | 30 days |
| Versioning | Enabled |
| Snapshot Frequency | Every 4 hours (via Azure Backup) |

**Configure Azure Backup**:
```bash
# Create Recovery Services Vault
az backup vault create \
  --resource-group rg-onlyoffice-prod \
  --name rsv-onlyoffice-prod \
  --location eastus2

# Enable backup for file share
az backup protection enable-for-azurefileshare \
  --vault-name rsv-onlyoffice-prod \
  --resource-group rg-onlyoffice-prod \
  --storage-account stonlyofficeprodXXXX \
  --azure-file-share onlyoffice-data \
  --policy-name DailyPolicy
```

**Restore File Share**:
```bash
# List recovery points
az backup recoverypoint list \
  --vault-name rsv-onlyoffice-prod \
  --resource-group rg-onlyoffice-prod \
  --container-name "StorageContainer;storage;rg-onlyoffice-prod;stonlyofficeprodXXXX" \
  --item-name "AzureFileShare;onlyoffice-data" \
  --query "[0:5].{Name:name, Time:properties.recoveryPointTime}"

# Restore to alternate location
az backup restore restore-azurefileshare \
  --vault-name rsv-onlyoffice-prod \
  --resource-group rg-onlyoffice-prod \
  --rp-name <recovery-point-name> \
  --container-name "StorageContainer;..." \
  --item-name "AzureFileShare;onlyoffice-data" \
  --restore-mode AlternateLocation \
  --target-storage-account stonlyofficeprodXXXX \
  --target-file-share onlyoffice-data-restored
```

#### 1.4 AKS Configuration

| Aspect | Configuration |
|--------|--------------|
| Backup Method | GitOps (Helm charts in Git) |
| State Storage | Terraform state in Azure Blob |
| Frequency | Every commit (CI/CD) |

All Kubernetes configurations are stored as code:
- Helm charts in `kubernetes/helm/`
- Terraform state in Azure Blob Storage
- Secrets in Azure Key Vault

---

### 2. Disaster Recovery Plan

#### 2.1 Scenario: Single Pod Failure
- **Detection**: Kubernetes health probes (automatic)
- **Recovery**: Automatic pod restart via deployment controller
- **RTO**: < 5 minutes
- **Impact**: Minimal (PDB ensures min 2 pods available)

#### 2.2 Scenario: Node Failure
- **Detection**: AKS node health monitoring
- **Recovery**: Cluster autoscaler provisions new node, pods rescheduled
- **RTO**: < 15 minutes
- **Impact**: Temporary reduced capacity

#### 2.3 Scenario: Availability Zone Failure
- **Detection**: Azure Monitor alerts
- **Recovery**: Pods rescheduled to remaining zones
- **RTO**: < 15 minutes
- **Impact**: Reduced capacity (2/3 zones remain)
- **Mitigations**:
  - Pods spread across 3 AZs via `topologySpreadConstraints`
  - PostgreSQL HA with zone-redundant standby
  - Redis deployed with zone redundancy
  - Storage uses ZRS replication

#### 2.4 Scenario: Region Failure
- **Detection**: Azure Service Health alerts
- **Recovery**: Manual failover to secondary region
- **RTO**: 4 hours
- **Procedure**:
  1. Activate DR region Terraform workspace
  2. Restore PostgreSQL from geo-redundant backup
  3. Deploy AKS cluster and application in DR region
  4. Update DNS to point to DR region
  5. Verify health and functionality

#### 2.5 Scenario: Data Corruption
- **Detection**: Application errors, user reports
- **Recovery**: Point-in-time restore of PostgreSQL + file share
- **RTO**: 2 hours
- **Procedure**:
  1. Identify corruption timestamp
  2. PITR PostgreSQL to before corruption
  3. Restore file share from snapshot
  4. Redeploy application with restored data
  5. Validate data integrity

#### 2.6 Scenario: Security Breach
- **Detection**: Microsoft Defender alerts, anomalous activity
- **Recovery**: Isolate, investigate, redeploy
- **RTO**: 4-8 hours
- **Procedure**:
  1. Isolate compromised resources (NSG deny rules)
  2. Rotate all secrets and credentials
  3. Review audit logs for scope of breach
  4. Redeploy from known-good state (clean infrastructure)
  5. Restore data from pre-compromise backup
  6. Post-incident review

---

### 3. DR Testing Schedule

| Test Type | Frequency | Duration | Participants |
|-----------|-----------|----------|-------------|
| Backup restore verification | Weekly (automated) | 30 min | CI/CD |
| Pod failure simulation | Monthly | 1 hour | Platform team |
| Zone failure simulation | Quarterly | 2 hours | Platform + Dev team |
| Full DR exercise | Semi-annually | 4 hours | All teams |
| Tabletop exercise | Annually | 2 hours | Management + Ops |

### 4. Backup Verification Checklist

- [ ] PostgreSQL PITR tested successfully
- [ ] File share restore verified
- [ ] Redis can recover from RDB snapshot
- [ ] Terraform can recreate infrastructure from scratch
- [ ] Helm can redeploy application to new cluster
- [ ] DNS failover procedure documented and tested
- [ ] Secrets accessible from Key Vault backup
- [ ] Monitoring alerts fire correctly during DR test
