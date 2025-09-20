# Azure RG → Terraform (AVM‑first) — **Prompt**

> **Run non‑interactively.** Execute all steps below without asking questions. Use the **Instructions** doc in this workspace for policy and constraints.
**Use the instructions document in this repository under:** `.github\instructions\azure-rg-to-terraform.instructions.md` (required)

## 0) Load Inputs

1. Read `.copilot/azure-rg.inputs.json` from the workspace root.
2. Extract:
   - `subscriptionId`, `tenantId`, `resourceGroup`, `targetPath`
   - discovery preferences
   - terraform backend + provider config
   - naming prefs
3. Create the `<targetPath>` directory in memory (emit files only once at the end).

If the file is missing or invalid JSON, **stop and emit** a single error README explaining the issue, but still scaffold a minimal Terraform with placeholders.

---

## 1) Discover Azure Inventory (deterministic)

Follow this order; use the **first available** surface. Record which one was used:

1. **Azure Resource Graph (ARG)**: Query the `Resources` table filtered to the given resource group. Fetch columns: `id`, `name`, `type`, `location`, `kind`, `sku`, `tags`, `properties`. For each `id`, infer possible child collections (diagnostics, private endpoints, DNS records, networking sub‑resources).
2. **ARM GET**: If ARG is not available, perform HTTP GET for each resource `id` to retrieve full JSON, then probe well‑known `child` endpoints (e.g., `providers/Microsoft.Network/virtualNetworks/<vnet>/subnets`, `.../privateEndpointConnections`, `.../diagnosticSettings`).
3. **Azure Tools API** (VS Code): If exposed, traverse the subscription → RG and collect resources, then hydrate details using the tool’s get‑properties endpoint.
4. **Workspace JSON**: If both 1–3 are unavailable, read and merge JSON documents from `discovery.workspaceJsonGlobs`.

Normalize each resource to a common shape including `children`.

---

## 2) Plan Terraform Mapping

1. Build a mapping from Azure `type` (e.g., `Microsoft.Storage/storageAccounts`) to **AVM module** when official names are known; otherwise mark as provider fallback.
2. Group resources by service area (networking, compute, data, app, identity).
3. Determine inter‑resource references (e.g., subnet IDs, private endpoint targets, identity links). Prefer outputs/inputs over `depends_on`.

---

## 3) Emit Terraform (single write phase)

Create files under `<targetPath>` **using the exact “Create:” blocks**:

1. **`providers.tf`**
   - Pin `azurerm` (~> latest major), enable `features {}`.
   - Provide `required_version` for Terraform (e.g., `>= 1.7.0`).

2. **`backend.tf`**
   - If backend is provided in inputs, emit the `terraform { backend "azurerm" { … } }` stanza.
   - Else emit a local backend with a README warning.

3. **`variables.tf`**
   - `subscription_id`, `tenant_id`, `location`, naming vars (`prefix`, `environment`).
   - Validations where useful.

4. **`data.tf`**
   - `data "azurerm_client_config" "current" {}`
   - `data "azurerm_resource_group" "rg" { name = var.resource_group }` (+ define `variable "resource_group"`).

5. **`main.tf`**
   - For each discovered resource:
     - If AVM exists → emit a **module** with inputs mapped from discovery JSON.
     - Else → emit `azurerm_*` resources that best reflect the settings.
   - Keep blocks grouped by service area with clear comments.

6. **`imports.tf`**
   - Emit an `import` block for **every** module/resource.
   - For AVM, target the module’s internal resource address as documented (include a comment with the specific address mapping if non‑obvious).
   - For provider resources, import by `id` → `azurerm_<type>.<name>`.

7. **`outputs.tf`**
   - Useful IDs, names, FQDNs, endpoints.

8. **`README.md`**
   - Discovery surface used and missing.
   - Resource counts (AVM vs provider fallback).
   - TODOs for sub‑settings that have no input in AVM today.
   - How to run: `terraform init`, `terraform plan`, `terraform apply` (with caution) and `terraform import`.


> **Do not** write files incrementally. Prepare content then emit all “Create:” blocks once, in the order above.

---

## 4) AVM Preference & Examples (inline hints)

When mapping, use **official AVM** names where known. Examples (non‑exhaustive):

- **VNet & Subnets** → `Azure/avm-res-network-virtualnetwork`
- **Public IP** → `Azure/avm-res-network-publicipaddress`
- **Private DNS Zone** → `Azure/avm-res-privatedns-zone`
- **Storage Account** → `Azure/avm-res-stor-storageaccount` (+ containers/shares via inputs or child modules)
- **Key Vault** → `Azure/avm-res-keyvlt-vault`

If uncertain whether an official AVM exists, **fallback immediately** to `azurerm_*` and add a TODO with a link placeholder to the AVM catalog.

---

## 5) Import Blocks — Addressing Pattern

- AVM example (comment):
  ```hcl
  # module.storage_account.azurerm_storage_account.this[0]
  import {
    to = module.storage_account.azurerm_storage_account.this[0]
    id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<name>"
  }
  ```

- Provider example:
  ```hcl
  import {
    to = azurerm_private_dns_zone.pdz
    id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/<zone>"
  }
  ```

Adjust addresses according to the module internals; include comments to guide the operator.

---

## 6) Determinism & Naming

- Derive HCL resource names from Azure names sanitized to `[a-z0-9_]+` and prefixed by `var.prefix` where appropriate.
- Sort blocks by `type/name` ascending for stable diffs.

---

## 7) Finalize

- Emit the file set via **Create blocks** to `<targetPath>`.
- If discovery used workarounds or AVM gaps exist, list them in `README.md`.

> End of prompt. Execute now.