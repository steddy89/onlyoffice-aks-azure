# Security Hardening Guide

## ONLYOFFICE Document Server on Azure AKS

### 1. Identity & Access Management

#### Azure AD Integration
- **AKS RBAC**: Azure AD-integrated RBAC enabled on the cluster
- **Workload Identity**: Pods use Azure Workload Identity (not service principal keys)
- **Managed Identity**: AKS cluster uses User-Assigned Managed Identity
- **Key Vault RBAC**: Role-based access control (not access policies)

#### Least Privilege Roles
| Identity | Role | Scope |
|----------|------|-------|
| AKS Kubelet | AcrPull | Container Registry |
| AKS Identity | Network Contributor | VNet |
| CI/CD Pipeline | Contributor | Resource Group |
| Ops Team | AKS Cluster Admin | AKS Cluster |
| Dev Team | AKS Cluster User | AKS Cluster |

#### Recommendations
- [ ] Enable Conditional Access for Azure Portal
- [ ] Enforce MFA for all admin accounts
- [ ] Use PIM (Privileged Identity Management) for JIT access
- [ ] Rotate service principal credentials every 90 days
- [ ] Review access permissions quarterly

---

### 2. Network Security

#### Architecture
```
Internet → Azure Front Door (WAF) → Application Gateway → AKS (VNet)
                                                              ↓
                                              Private Endpoints:
                                              - PostgreSQL (snet-db)
                                              - Redis (snet-redis)
                                              - Key Vault (snet-pe)
                                              - Storage (snet-pe)
                                              - ACR (snet-pe)
```

#### NSG Rules Applied
- AKS subnet: Only allows traffic from AppGw subnet on port 443
- DB subnet: Only allows port 5432 from AKS subnet
- All subnets: Default deny inbound

#### Recommendations
- [ ] Enable Azure DDoS Protection Standard
- [ ] Configure WAF policy with OWASP 3.2 ruleset
- [ ] Enable Azure Firewall for egress filtering
- [ ] Use Private Link for all PaaS services
- [ ] Enable AKS Network Policy (Calico) enforcement
- [ ] Regular NSG flow log review

---

### 3. Data Protection

#### Encryption at Rest
| Resource | Encryption | Key Management |
|----------|-----------|----------------|
| PostgreSQL | AES-256 | Microsoft-managed (CMK optional) |
| Redis | AES-256 | Microsoft-managed |
| Storage | AES-256 | Microsoft-managed (CMK optional) |
| AKS Disks | AES-256 | Microsoft-managed |
| Key Vault | HSM-backed | Platform-managed |

#### Encryption in Transit
- TLS 1.2+ enforced on all services
- PostgreSQL: `require_secure_transport = on`
- Redis: SSL-only (`enable_non_ssl_port = false`)
- Storage: HTTPS only (`https_traffic_only_enabled = true`)
- AGIC: TLS termination with certificate

#### Recommendations
- [ ] Enable Customer-Managed Keys (CMK) for PostgreSQL
- [ ] Enable CMK for Storage Account
- [ ] Configure certificate auto-rotation via cert-manager
- [ ] Enable Azure Disk Encryption for AKS nodes
- [ ] Store all secrets in Key Vault (never in ConfigMaps)

---

### 4. Container Security

#### Image Security
- Images pulled from ACR (private registry, not Docker Hub)
- Content trust enabled on ACR (Premium SKU)
- Regular vulnerability scanning via Microsoft Defender for Containers

#### Pod Security
```yaml
# Applied via Helm values
securityContext:
  capabilities:
    drop:
      - NET_RAW
  readOnlyRootFilesystem: false  # Required by ONLYOFFICE

podSecurityContext:
  fsGroup: 101
```

#### Recommendations
- [ ] Enable Microsoft Defender for Containers
- [ ] Implement admission controllers (OPA/Gatekeeper)
- [ ] Scan images on push to ACR
- [ ] Pin image versions (avoid `latest` tag)
- [ ] Run containers as non-root where possible
- [ ] Implement resource quotas per namespace
- [ ] Enable Azure Policy for AKS

---

### 5. Kubernetes Security

#### RBAC Configuration
```yaml
# Namespace-scoped roles for ONLYOFFICE
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: onlyoffice-operator
  namespace: onlyoffice
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "update"]
```

#### Network Policies
- Ingress limited to kube-system and within namespace
- Egress allowed (required for DB, Redis, Storage connections)
- Pod-to-pod communication restricted by label selectors

#### Recommendations
- [ ] Enable audit logging (kube-audit-admin)
- [ ] Disable anonymous auth on API server
- [ ] Enable pod security admission (restricted profile)
- [ ] Limit service account token auto-mounting
- [ ] Regular RBAC permission review

---

### 6. Secret Management

#### Current Implementation
- All secrets stored in Azure Key Vault
- CSI Secret Store Driver enabled on AKS
- Secret rotation enabled (2-minute interval)
- Kubernetes secrets created from Key Vault references

#### Secret Inventory
| Secret | Location | Rotation |
|--------|----------|----------|
| PostgreSQL password | Key Vault | Manual (quarterly) |
| Redis access key | Key Vault | Manual (quarterly) |
| JWT secret | Key Vault | Manual (annually) |
| TLS certificate | Kubernetes Secret | Auto (cert-manager) |
| Storage account key | Key Vault | Manual (quarterly) |

#### Recommendations
- [ ] Implement automated secret rotation
- [ ] Enable Key Vault audit logging
- [ ] Use Workload Identity for Key Vault access
- [ ] Never store secrets in source code or CI/CD variables
- [ ] Enable soft-delete and purge protection on Key Vault

---

### 7. Compliance & Auditing

#### Logging
- AKS control plane logs → Log Analytics
- Container logs → Log Analytics (Container Insights)
- Key Vault audit logs → Log Analytics
- PostgreSQL logs → Azure Monitor
- NSG flow logs → Storage Account

#### Recommendations
- [ ] Enable Microsoft Defender for Cloud
- [ ] Configure Azure Security Center recommendations
- [ ] Implement Azure Sentinel for SIEM
- [ ] Regular penetration testing (annual)
- [ ] Vulnerability assessment schedule (weekly)
- [ ] Compliance reporting (SOC 2, ISO 27001)

---

### 8. Incident Response

#### Runbook
1. **Detection**: Azure Monitor alerts → Action Group → Email/PagerDuty
2. **Triage**: Check dashboards, logs, pod status
3. **Containment**: Scale down, network isolation if compromised
4. **Recovery**: Restore from backup, redeploy from known-good state
5. **Post-mortem**: Document findings, update security controls

#### Emergency Contacts
| Role | Contact | Escalation |
|------|---------|------------|
| On-call Engineer | oncall@example.com | 15 min |
| Security Lead | security@example.com | 30 min |
| Platform Manager | manager@example.com | 1 hour |
