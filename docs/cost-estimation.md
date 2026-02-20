# Cost Estimation & Optimization

## ONLYOFFICE Document Server on Azure AKS

### Monthly Cost Estimate (Production)

| Resource | SKU | Quantity | Est. Monthly Cost |
|----------|-----|----------|-------------------|
| **AKS System Nodes** | Standard_D4s_v5 | 3 nodes | ~$420 |
| **AKS User Nodes** | Standard_D8s_v5 | 2-10 nodes | ~$560 - $2,800 |
| **PostgreSQL Flexible** | GP_Standard_D4s_v3 | 1 (HA) | ~$520 |
| **Redis Premium** | P1 (6GB) | 1 | ~$305 |
| **Storage (Files)** | Premium ZRS 100GB | 1 | ~$17 |
| **Container Registry** | Premium | 1 | ~$50 |
| **Key Vault** | Premium | 1 | ~$5 |
| **Log Analytics** | PerGB2018 | ~50 GB/mo | ~$130 |
| **Application Gateway** | v2 WAF | 1 | ~$325 |
| **Public IP** | Standard | 1 | ~$4 |
| **Private Endpoints** | 5 endpoints | 5 | ~$50 |
| | | **Total (min)** | **~$2,386/mo** |
| | | **Total (max)** | **~$4,626/mo** |

### Cost Optimization Recommendations

#### Immediate Savings
1. **Reserved Instances** (1-year): 35-40% savings on VMs
   - AKS nodes: ~$400/mo savings
   - PostgreSQL: ~$180/mo savings
2. **Dev/Test pricing**: Use Azure Dev/Test subscription for non-prod
3. **Spot instances**: Use for non-critical batch processing node pools

#### Architecture Optimizations
1. **Right-size PostgreSQL**: Start with B_Standard_B4ms, upgrade when needed
2. **Redis Standard**: Use Standard instead of Premium if VNet injection not required
3. **Autoscaling**: Ensure AKS autoscaler is configured properly to scale down
4. **Log retention**: Reduce from 90 to 30 days in non-prod

#### Monitoring Cost
- Set daily ingestion cap on Log Analytics for non-prod
- Use Basic logs tier for high-volume, low-query data
- Configure Azure Advisor cost recommendations
