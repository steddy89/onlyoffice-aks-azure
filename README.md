# ONLYOFFICE Document Server on Azure AKS

[![CI Pipeline](https://github.com/YOUR_ORG/onlyoffice-aks-azure/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_ORG/onlyoffice-aks-azure/actions/workflows/ci.yml)
[![CD Pipeline](https://github.com/YOUR_ORG/onlyoffice-aks-azure/actions/workflows/cd.yml/badge.svg)](https://github.com/YOUR_ORG/onlyoffice-aks-azure/actions/workflows/cd.yml)

Production-ready deployment of [ONLYOFFICE Document Server](https://www.onlyoffice.com/document-server.aspx) on **Microsoft Azure Kubernetes Service (AKS)**, built following the [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/) five pillars:

| Pillar | Implementation |
|--------|---------------|
| **Reliability** | Multi-AZ AKS, zone-redundant PostgreSQL HA, Redis persistence, PodDisruptionBudgets |
| **Security** | Private endpoints, Calico network policies, Workload Identity, Key Vault CSI, WAF |
| **Cost Optimization** | Cluster autoscaler (2–10 nodes), HPA, dev/prod tfvars, spot-ready node pools |
| **Operational Excellence** | GitOps CI/CD, Prometheus + Grafana, Fluent Bit, automated backup verification |
| **Performance Efficiency** | Premium SSD storage, topology-aware scheduling, pod anti-affinity, Redis caching |

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        Azure Region                          │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                    Virtual Network                     │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐│  │
│  │  │ App GW   │  │  AKS     │  │  Private Endpoints   ││  │
│  │  │ (WAF v2) │──│  Cluster │──│  ┌────────────────┐  ││  │
│  │  │          │  │          │  │  │ PostgreSQL     │  ││  │
│  │  └──────────┘  │ ┌──────┐ │  │  │ Redis          │  ││  │
│  │                │ │ONLY- │ │  │  │ Key Vault      │  ││  │
│  │                │ │OFFICE│ │  │  │ ACR            │  ││  │
│  │                │ │Pods  │ │  │  │ Storage        │  ││  │
│  │                │ └──────┘ │  │  └────────────────┘  ││  │
│  │                └──────────┘  └──────────────────────┘│  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ Log Analytics│  │ App Insights │  │ Azure Monitor    │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

See [docs/architecture.md](docs/architecture.md) for detailed Mermaid diagrams.

---

## Project Structure

```
onlyoffice-aks-azure/
├── .github/
│   └── workflows/
│       ├── ci.yml                 # PR validation (lint, scan, plan)
│       ├── cd.yml                 # Deploy to dev → staging → prod
│       └── maintenance.yml        # Scheduled backup & security checks
├── terraform/
│   ├── main.tf                    # Root module orchestration
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── versions.tf                # Provider versions & backend
│   ├── environments/
│   │   ├── dev.tfvars             # Development overrides
│   │   └── prod.tfvars            # Production overrides
│   └── modules/
│       ├── networking/            # VNet, subnets, NSGs, private DNS
│       ├── aks/                   # AKS cluster, node pools, RBAC
│       ├── postgresql/            # Flexible Server, HA, firewall
│       ├── redis/                 # Premium cache, VNet injection
│       ├── keyvault/              # Premium vault, RBAC, private EP
│       ├── acr/                   # Container registry, geo-replication
│       ├── storage/               # Premium Files ZRS, file shares
│       ├── monitoring/            # Log Analytics, alerts, dashboards
│       └── onlyoffice-helm/       # Helm release via Terraform
├── kubernetes/
│   ├── helm/
│   │   └── onlyoffice-docserver/  # Helm chart
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   │           ├── _helpers.tpl
│   │           ├── deployment.yaml
│   │           ├── service.yaml
│   │           ├── ingress.yaml
│   │           ├── hpa.yaml
│   │           └── extras.yaml    # PDB, SA, NetworkPolicy
│   └── monitoring/
│       ├── prometheus-rules.yaml
│       └── fluent-bit-config.yaml
├── docs/
│   ├── architecture.md            # Mermaid architecture diagrams
│   ├── security-hardening.md      # Security guide
│   ├── backup-dr-strategy.md      # Backup & disaster recovery
│   ├── operations-runbook.md      # Day-2 operations guide
│   └── cost-estimation.md         # Cost breakdown & optimization
├── .gitignore
├── .editorconfig
├── Makefile
└── README.md                      # ← You are here
```

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Terraform](https://www.terraform.io/) | ≥ 1.7.0 | Infrastructure provisioning |
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) | ≥ 2.55 | Azure authentication & management |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | ≥ 1.29 | Kubernetes cluster management |
| [Helm](https://helm.sh/) | ≥ 3.14 | Application deployment |
| [kubelogin](https://github.com/Azure/kubelogin) | latest | AAD authentication for kubectl |

### Azure Subscription Requirements

- **Resource Providers**: `Microsoft.ContainerService`, `Microsoft.Network`, `Microsoft.DBforPostgreSQL`, `Microsoft.Cache`, `Microsoft.KeyVault`, `Microsoft.ContainerRegistry`, `Microsoft.Storage`, `Microsoft.OperationalInsights`, `Microsoft.Insights`
- **Quota**: At minimum 24 vCPUs in the target region for Standard_D-series v5

```powershell
# Register required resource providers
$providers = @(
    "Microsoft.ContainerService",
    "Microsoft.Network",
    "Microsoft.DBforPostgreSQL",
    "Microsoft.Cache",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry",
    "Microsoft.Storage",
    "Microsoft.OperationalInsights",
    "Microsoft.Insights"
)
foreach ($p in $providers) {
    az provider register --namespace $p
}
```

---

## Quick Start

### 1. Clone & Configure

```bash
git clone https://github.com/YOUR_ORG/onlyoffice-aks-azure.git
cd onlyoffice-aks-azure
```

### 2. Bootstrap Terraform State Backend

```bash
# Create resource group and storage account for Terraform state
az group create --name rg-terraform-state --location eastus2
az storage account create \
    --name stterraformstate$(openssl rand -hex 4) \
    --resource-group rg-terraform-state \
    --sku Standard_ZRS \
    --encryption-services blob
az storage container create \
    --name tfstate \
    --account-name <STORAGE_ACCOUNT_NAME>
```

Update `terraform/versions.tf` backend block with your storage account details.

### 3. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan with environment-specific variables
terraform plan -var-file=environments/dev.tfvars -out=tfplan

# Apply
terraform apply tfplan
```

### 4. Connect to AKS

```bash
# Get credentials
az aks get-credentials \
    --resource-group $(terraform output -raw resource_group_name) \
    --name $(terraform output -raw aks_cluster_name) \
    --overwrite-existing

# Convert to AAD auth
kubelogin convert-kubeconfig -l azurecli

# Verify
kubectl get nodes
kubectl get pods -n onlyoffice
```

### 5. Verify ONLYOFFICE

```bash
# Check pod health
kubectl get pods -n onlyoffice -l app.kubernetes.io/name=onlyoffice-docserver

# Get the external endpoint
kubectl get ingress -n onlyoffice

# Test health endpoint
curl -k https://<INGRESS_HOST>/healthcheck
```

---

## Configuration

### Environment Variables (tfvars)

| Variable | Dev Default | Prod Default | Description |
|----------|-------------|--------------|-------------|
| `environment` | `dev` | `prod` | Deployment environment |
| `aks_system_node_count` | 1 | 3 | System node pool size |
| `aks_user_node_vm_size` | D4s_v5 | D8s_v5 | User node VM SKU |
| `aks_user_node_min_count` | 1 | 2 | Autoscaler minimum |
| `aks_user_node_max_count` | 3 | 10 | Autoscaler maximum |
| `db_sku_name` | B_Standard_B2ms | GP_Standard_D4s_v3 | PostgreSQL SKU |
| `db_ha_mode` | Disabled | ZoneRedundant | PostgreSQL HA |
| `redis_sku` | Standard | Premium | Redis tier |
| `onlyoffice_replicas` | 1 | 3 | Initial pod replicas |

See `terraform/variables.tf` for the full list.

### Helm Values

Override ONLYOFFICE-specific settings in `kubernetes/helm/onlyoffice-docserver/values.yaml`:

```yaml
replicaCount: 3
image:
  repository: onlyoffice/documentserver
  tag: "8.0"
resources:
  requests:
    cpu: "1000m"
    memory: "2Gi"
  limits:
    cpu: "4000m"
    memory: "8Gi"
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

---

## CI/CD Pipeline

### Pull Request (CI)

```
PR opened → Terraform fmt/validate → TFLint → Checkov scan →
            Terraform plan → Helm lint → kubeconform → Trivy scan
```

### Deployment (CD)

```
Main merge → Terraform apply (dev) → Helm upgrade → Smoke tests →
             Manual approval → Terraform apply (prod) → Helm upgrade →
             Smoke tests → Notify
```

### Maintenance (Scheduled)

- **Daily**: Backup verification (PostgreSQL, Redis, Storage)
- **Weekly**: Trivy vulnerability scan, cost report via Azure Advisor
- **Monthly**: Certificate expiry check

See `.github/workflows/` for full pipeline definitions.

---

## Operations

| Task | Command |
|------|---------|
| Scale pods | `kubectl scale deployment onlyoffice-docserver -n onlyoffice --replicas=5` |
| View logs | `kubectl logs -n onlyoffice -l app.kubernetes.io/name=onlyoffice-docserver --tail=100` |
| Restart pods | `kubectl rollout restart deployment/onlyoffice-docserver -n onlyoffice` |
| Force upgrade | `helm upgrade onlyoffice-docserver ./kubernetes/helm/onlyoffice-docserver -n onlyoffice` |
| Check HPA | `kubectl get hpa -n onlyoffice` |
| Get metrics | `kubectl top pods -n onlyoffice` |

See [docs/operations-runbook.md](docs/operations-runbook.md) for the full runbook.

---

## Security

Key security controls implemented:

- **Network isolation**: Private endpoints for all PaaS services, Calico network policies
- **Identity**: Azure AD Workload Identity, AKS-managed RBAC, no local accounts
- **Secrets**: Key Vault with CSI driver, no secrets in code or environment variables
- **Runtime**: Read-only root filesystem, non-root containers, security contexts
- **WAF**: Application Gateway WAF v2 with OWASP 3.2 ruleset
- **Scanning**: Checkov IaC scanning, Trivy container scanning in CI

See [docs/security-hardening.md](docs/security-hardening.md) for the complete security guide.

---

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/architecture.md) | System architecture with Mermaid diagrams |
| [Security Hardening](docs/security-hardening.md) | Security controls and compliance guide |
| [Backup & DR](docs/backup-dr-strategy.md) | Backup strategy and disaster recovery procedures |
| [Operations Runbook](docs/operations-runbook.md) | Day-2 operations and troubleshooting |
| [Cost Estimation](docs/cost-estimation.md) | Cost breakdown and optimization tips |

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -m 'Add my feature'`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request — CI pipeline validates automatically

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

ONLYOFFICE Document Server is licensed under the [GNU AGPL v3](https://www.gnu.org/licenses/agpl-3.0.html).
