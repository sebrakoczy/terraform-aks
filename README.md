# Multi-Region AKS with Terraform — Active/Active & Active/Passive

Terraform configuration for deploying Azure Kubernetes Service (AKS) across multiple regions, with Azure Traffic Manager demonstrating both Active/Active and Active/Passive architectures.

## Architecture
┌─────────────────────┐
                │   Traffic Manager    │
                │  (Weighted/Priority) │
                └──────┬───────┬──────┘
                       │       │
          ┌────────────┘       └────────────┐
          ▼                                  ▼
## Structure
## Multi-Region via Workspaces

Each Terraform workspace maps to a region through a `region_config` lookup:

```hcl
locals {
  region_config = {
    eastus  = { location = "eastus",  vnet_address_space = ["10.10.0.0/16"], ... }
    westus2 = { location = "westus2", vnet_address_space = ["10.20.0.0/16"], ... }
  }
  cfg = local.region_config[terraform.workspace]
}
```

```bash
terraform workspace select eastus  && terraform apply
terraform workspace select westus2 && terraform apply
terraform workspace select default && terraform apply   # Traffic Manager
```

Non-overlapping CIDRs per region keep the door open for VNet peering.

## Active/Active vs Active/Passive

Routing method is a variable on the Traffic Manager profile:

```bash
# Active/Active — both regions serve traffic (DNS round-robin by weight)
terraform apply -var="tm_routing_method=Weighted"

# Active/Passive — priority 1 serves; priority 2 is standby
terraform apply -var="tm_routing_method=Priority"
```

**Failover drill** (tested): with Priority routing, scaling the primary region's deployment to 0 caused Traffic Manager health probes to mark it degraded; DNS failed over to the standby region in ~90 seconds (probe interval 30s × 3 tolerated failures). Restoring the primary triggered automatic failback.

Key trade-off: Traffic Manager is **DNS-based** — failover speed is bounded by probe interval + DNS TTL + client caching. Azure Front Door (anycast L7 proxy) fails over faster and adds WAF/caching, at higher cost and complexity.

## Design Decisions

- **System-assigned managed identity** with `AcrPull` on ACR — no static registry credentials
- **Network Contributor on the VNet** for the cluster identity — required for internal LoadBalancer provisioning in a custom VNet
- **Azure CNI + Azure network policy** — pods get VNet IPs; NetworkPolicy support
- **Internal + public LoadBalancers** — `service.beta.kubernetes.io/azure-load-balancer-internal` annotation for private VNet-only exposure

## Lessons Learned

1. **Don't layer a custom subnet NSG over AKS's managed NIC NSG.** AKS auto-manages a NIC-level NSG with precise per-service rules. A custom subnet-level NSG — even with seemingly-correct allow rules for `AzureLoadBalancer` and the NodePort range — blocked LoadBalancer traffic. Both NSG layers must independently allow traffic; debugging required checking effective rules at the NIC level. Removing the redundant subnet NSG association resolved it.
2. **Pin Kubernetes versions deliberately.** A hardcoded `1.28` failed at apply time — aged out of region support. `az aks get-versions --location <region>` is the source of truth.
3. **Subscription SKU quotas vary by region.** `Standard_B2s` was unavailable for this subscription in eastus; the error response lists allowed SKUs.
4. **Internal LBs need RBAC.** The 403 from the cloud-controller-manager pointed directly at the missing `Microsoft.Network/virtualNetworks/subnets/read` permission for the cluster identity.
