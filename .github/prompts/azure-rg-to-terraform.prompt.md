---
mode: agent
description: **EXECUTE NOW (single pass).** Scan ALL Azure resources (and sub-resources) in the given resource group using the Azure MCP server, then generate Terraform (AVM-first) **and** `imports.tf` with `to:` + `id:` for every discovered object. **Windows paths** only. **Do NOT create the resource group** in Terraform.
---

# Azure RG → Terraform (ALL resources + subresources) — **DO, don’t plan**

[Rules & matrix](..\\instructions\\azure-rg-to-terraform.instructions.md)

## Non‑interactive contract
- **Don’t ask questions. Don’t propose a plan. Execute now.**
- **Never** create a folder named after this command. Write files **only** to `<target_path>`.
- **Never** create `resource "azurerm_resource_group"`. The RG already exists; use `data.azurerm_resource_group.rg`.
- **Windows paths** only (e.g., `infra\\rg-name`).
- Use the **Create: <path> + fenced code block** pattern for every file.

## Inputs (resolve in this exact order)
1) Inline `${input:...}` values below.  
2) If any is `__auto__`, load **attached** `#file:.copilot/azure-rg.inputs.json`.  
3) If still `__auto__`, accept a fenced ```json block in this message.  
4) If still missing, compute defaults where noted; only `subscription_id` and `resource_group` are required — if missing, ask **once** and continue.

- **subscription_id**: ${input:subscription_id:__auto__}
- **resource_group**: ${input:resource_group:__auto__}
- **target_path**: ${input:target_path:__auto__}          <!-- default: infra\\<resource_group> -->
- **providers_filter**: ${input:providers_filter:__auto__} <!-- default: [] = ALL -->
- **prefer_avm**: ${input:prefer_avm:__auto__}             <!-- default: true -->
- **tf_required_version**: ${input:tf_required_version:__auto__}   <!-- default: >= 1.5.0 -->
- **azurerm_version**: ${input:azurerm_version:__auto__}           <!-- default: ~> 3.113 -->
- **azapi_version**: ${input:azapi_version:__auto__}               <!-- default: ~> 1.13 -->
- **location_fallback**: ${input:location_fallback:__auto__}
- **name_prefix**: ${input:name_prefix:__auto__}
- **include_subresources**: ${input:include_subresources:__auto__} <!-- default: true -->
- **subresource_depth**: ${input:subresource_depth:__auto__}       <!-- default: all -->
- **api_version_strategy**: ${input:api_version_strategy:__auto__} <!-- default: latest -->

**Echo once, then continue**: `inputs_source`, `subscription_id`, `resource_group`, `target_path`.

## Enumerate EVERYTHING (parents + children)
- Set subscription via MCP.
- **Parents:** `az resource list -g <rg> --output json`.
- **Children (BFS sweep):** For each parent, call the ARM list endpoints from the **Subresource Matrix** (VNets→Subnets, NSGs→Rules, RouteTables→Routes, NIC→IPConfigs, LB/AppGW children, Private DNS links/records, Storage containers/shares/queues/tables, AKS agent pools, VMSS instances). Add every child with its **full ARM id**.
- Deduplicate by `id`. Build a normalized inventory: `{id, type, name, location, parent_id, properties}`.

## Full-settings capture (state replication mode)
For every discovered object:
1) Perform `GET <ARM ID>?api-version=<latest>` to fetch full resource JSON.
2) Build TF from the **real settings**:
   - If an official AVM covers the **parent** type: pass settings via the AVM’s inputs (children like subnets live in module collections).
   - If the AVM lacks an input for a property, **preserve it via AzAPI**:
     - Either a dedicated child `azapi_resource` expected by the AVM, or
     - A root-level `azapi_resource` with:
       - `type  = "<Namespace/Type@<apiVersion>"`
       - `name  = "<safe-name>"`
       - `parent_id = "<ARM parent id>"` (when applicable)
       - `location = <from RG or resource>`
       - `body = jsonencode(<ARM properties with unsupported fields kept>)`
       - `lifecycle { ignore_changes = [body] }`
3) Strip **computed/read-only** fields from arguments/bodies: `id`, `type`, `name` (if provided by module), `etag`, `resourceGuid`, `systemData`, `provisioningState`, timestamps, and provider `Computed` attributes.
4) Emit an **import** with `id = "<ARM ID>"`:
   - If in an AVM module, set `to = module.<mod>.<TYPE>.<NAME>[...]` **exactly as defined** by the AVM internals (use inventory from downloaded module `.tf` files).
   - Else target the declared `azurerm_*` or `azapi_resource.*`.


## AVM preference (official only)
- Use **official AVM modules** only (Terraform Registry `Azure/avm-res-*`):
  - `Microsoft.Network/virtualNetworks` → `Azure/avm-res-network-virtualnetwork/azurerm`
  - `Microsoft.Storage/storageAccounts` → `Azure/avm-res-storage-storageaccount/azurerm`
- If no official AVM exists for a type, use root‑level `azurerm_*`. Unknowns → `azapi_resource`.

## Pin AVM versions (deterministic & correct folder)
1) Ensure <target_path> exists (create if missing).
2) Run: terraform -chdir="<target_path>" init -upgrade -backend=false
3) Read "<target_path>\.terraform\modules\modules.json". For each
   entry whose Source starts with "registry.terraform.io/Azure/avm-res-",
   set that exact "Version" back into "<target_path>\main.tf" for the
   matching module (source = "Azure/avm-res-.../azurerm").
4) Fail if any module still has version = "0.0.0-placeholder" or "1.0.0".


## AVM version pinning (must pin real latest)
- When writing each AVM `module` block, set `version = "0.0.0-placeholder"` temporarily.
- Immediately run `terraform -chdir="<target_path>" init -upgrade -backend=false` in `<target_path>` to fetch the **latest** official Azure AVM.
- Read `.terraform\modules\modules.json` and, for each `registry.terraform.io/Azure/avm-res-*` entry, extract its `"Version"`.
- Replace the placeholder in `main.tf` with the exact `"Version"` from `modules.json` for each module.
- Append the pinned versions to `README.md` under **Pinned AVM versions**.
- Fail if any AVM `version` remains unset or equals `1.0.0`. Never guess.

## Generate files (use **Create:** pattern)
Create in `<target_path>` in this order:

1) **versions.tf** — pin Terraform and providers.
2) **providers.tf** — providers, `data.azurerm_resource_group.rg`, locals.
3) **variables.tf** — `resource_group`, `name_prefix`, `location_fallback`.
4) **main.tf** — for each inventory object:
   - If AVM exists for its parent type, add/extend the proper AVM module with **just enough** inputs to match discovered state (children like subnets go in module inputs).
   - Else declare root `azurerm_*` (or `azapi_resource`) to model the object.
5) **imports.tf** — **one import per object**:
   - If represented by an AVM module: `to = module.<mod>.<TYPE>.<NAME>[...]` (or nested) **as defined in that AVM’s code** (often `azapi_resource.*` for VNets).
   - Else: `to = azurerm_*.<name>` (or `azapi_resource.<name>`).
   - Always set `id = "<FULL ARM ID>"`.
6) **outputs.tf** — useful names/ids.
7) **README.md** — summary, pinned AVM versions, counts, and an Import Address Report.

## AVM internal addresses (don’t guess)
- After writing `main.tf`, assume `terraform -chdir="<target_path>" init -backend=false` to fetch modules (no prompt).
- Build address inventory by reading module `.tf` files under `.terraform\\modules\\...`:
  - `resource "<TYPE>" "<NAME>"` → addresses are `module.<mod>.<TYPE>.<NAME>` (or `["key"]` / nested `.module.<child>`).
- If you can’t inspect the code, prefer **`azapi_resource.*`** addresses for the known AVMs above (vnet, storage account), and include a TODO to validate with `terraform validate`.

## AVM introspection (real module internals → import addresses)
- After writing main.tf and pinning versions, assume terraform -chdir="<target_path>" init -backend=false has downloaded sources into ".terraform\modules\...".
- Build an inventory by scanning those module .tf files for:
  resource "<TYPE>" "<NAME>"
- Construct imports **from this inventory** (do not guess):
  - Root:   module.<mod>.<TYPE>.<NAME>
  - for_each: module.<mod>.<TYPE>.<NAME>["<key>"]
  - Nested submodule: module.<mod>.module.<child>["<key>"].<TYPE>.<NAME>
- **Smart enforcement**:
  - Allow module.*.azurerm_* only if it actually exists in the AVM code.
  - If the AVM uses azapi_resource internally (e.g., vnet, subnet), rewrite any guessed azurerm_* target to the correct azapi_resource.* address.


## Output
- When done creating files, print: `DONE: <target_path>` and show a consolidated diff/patch of everything under `<target_path>` only.
- After `terraform -chdir="<target_path>" init -upgrade -backend=false`, if any AVM module still shows `version = "0.0.0-placeholder"` or `1.0.0`, re-read `.terraform\modules\modules.json` and fix; if unresolved, stop with a clear error.


