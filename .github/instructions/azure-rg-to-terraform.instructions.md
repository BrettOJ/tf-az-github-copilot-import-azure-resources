# Rules & Subresource Matrix (Windows)

## Hard rules
- **Execute now** (no planning questions).
- **Only** write to `<target_path>` using:
  ```
  Create: <RELATIVE\WINDOWS\PATH\FILENAME>
  ```hcl
  # file contents
  ```
- Resource group is **data only** (`data.azurerm_resource_group.rg`), never a managed resource.
- Prefer **official AVM** modules (Azure/avm-res-*). If none exists → use `azurerm_*`; if unknown → `azapi_resource`.
- **Imports:** emit one block per object with `to =` (correct AVM-internal address or root resource) and `id = "<ARM ID>"`.

### Version resolution (authoritative)
- Pin by **actual download result**, not guesses:
  1) Write module with `version = "0.0.0-placeholder"`.
  2) Run `terraform init -upgrade -backend=false` in `<target_path>`.
  3) Parse `.terraform\modules\modules.json`; for each `Azure/avm-res-*` entry, copy its `"Version"` back into `main.tf`.
  4) Record pinned versions in `README.md`.
- Never leave `1.0.0` or a placeholder.

### AVM introspection & unsupported fields
- Build import addresses from the **downloaded module inventory** (scan `.terraform\modules\*\*.tf` for `resource "<TYPE>" "<NAME>"`).
- If a property cannot be represented by AVM/azurerm inputs, add an **AzAPI** resource to carry that property with:
  `lifecycle { ignore_changes = [body] }`
  so that `terraform plan` is zero-change after import.

### Drop these fields when mirroring settings
id, type, name (when provided elsewhere), etag, resourceGuid, systemData, provisioningState, status, timestamps, provider-computed hashes, and any attribute documented as Computed.


## Subresource Matrix (enumerate with ARM REST)
**Network**
- virtualNetworks → subnets
- networkSecurityGroups → securityRules
- routeTables → routes
- networkInterfaces → ipConfigurations
- loadBalancers → backendAddressPools, loadBalancingRules, probes, inboundNatRules, outboundRules, frontendIPConfigurations
- applicationGateways → httpListeners, requestRoutingRules, backendAddressPools, backendHttpSettingsCollection, probes, frontendIPConfigurations
- privateEndpoints → privateDnsZoneGroups

**Private DNS**
- privateDnsZones → virtualNetworkLinks, recordSets

**Storage**
- storageAccounts → blobServices/default/containers, fileServices/default/shares, queueServices/default/queues, tableServices/default/tables

**Containers/Compute**
- managedClusters → agentPools
- virtualMachineScaleSets → virtualMachines

Use newest stable `api-version` per provider index. Add each child with full ARM `id`.

## File scaffolds (snippets)

**versions.tf**
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.113" }
    azapi   = { source = "azure/azapi",      version = "~> 1.13" }
  }
}
```

**providers.tf**
```hcl
provider "azurerm" { features {} }
provider "azapi" {}

data "azurerm_resource_group" "rg" { name = var.resource_group }

locals {
  name_prefix = var.name_prefix != "" ? var.name_prefix : var.resource_group
  location    = try(data.azurerm_resource_group.rg.location, var.location_fallback)
}
```

**variables.tf**
```hcl
variable "resource_group"    { type = string }
variable "name_prefix"       { type = string, default = "" }
variable "location_fallback" { type = string, default = null }
```

**imports.tf (example for AVM VNet & subnets)**
```hcl
import {
  to = module.vnet_main.azapi_resource.vnet
  id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<name>"
}
import {
  to = module.vnet_main.azapi_resource.subnet["snet-app"]
  id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<name>/subnets/snet-app"
}
```

**README.md** should list:
- How many objects discovered, by ARM type
- Which ones mapped to AVM vs azurerm vs AzAPI
- Pinned AVM versions
- Import Address Report (module + TYPE.NAME used)

