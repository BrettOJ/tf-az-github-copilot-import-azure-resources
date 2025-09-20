# Copilot Instructions — **Azure RG → Terraform (AVM‑first)**
**Mode:** Agent / Autonomous (no interactive questions)  
**Scope:** Given a Resource Group, discover all resources (including sub-resources & settings) and produce production‑grade Terraform. Prefer **Azure Verified Modules (AVM)** first; fall back to **azurerm\_\*** only if no AVM exists. Then generate **`import` blocks** for every created resource.

> ⚠️ **Important capability note**
> GitHub Copilot Chat cannot natively execute shell/CLI by itself. These instructions assume Copilot Chat has access to tools via **MCP** or equivalent (e.g., `azure_cli`, `azure_resource_graph`, `microsoft_graph`). If such tools are **not** available, Copilot must still complete all code generation deterministically but will not be able to fetch live Azure state. In that case, it should clearly state “**TOOLLESS MODE**” at the top of its output and proceed to scaffold Terraform folder structure and placeholders, plus a one‑shot script the user can run to backfill real IDs.

---

## Guardrails & Conventions
1. **AVM‑first:** Map each discovered resource to an AVM module if one exists (e.g., `Azure/avm-res-network-virtualnetwork`). Only use `azurerm_*` when no AVM supports the resource/sub‑resource. Document the reason in a comment.
2. **One RG at a time:** Only model resources whose **`resourceGroupName`** equals the target RG, except sub‑resources that logically belong to a parent in the RG.
3. **Deterministic outputs:** No “ask to proceed” prompts. Complete all steps end‑to‑end inside the chat response.
4. **Idempotent TF:** No hard‑coded GUIDs unless required; prefer variables and references. Centralize names, tags, location in `locals.tf` and `variables.tf`.
5. **Imports:** Emit **complete `import` blocks** matching the created resources, using the provider’s canonical IDs.
6. **Structure:**  
   ```text
   <out_dir>/
     modules/                # only if you need light wrappers around AVM
     env/
       main.tf               # providers, default RG/loc, data sources
       variables.tf
       outputs.tf
       locals.tf
       versions.tf
       <service>/            # one folder per service family (network, compute, storage, …)
         main.tf             # actual AVM resources or azurerm_* fallback
         variables.tf        # keep minimal; favor locals for discovered constants
         outputs.tf
     imports/
       import.tf             # all `import {}` blocks
     discovery/
       raw/*.json            # raw discovery payloads (ARG/Graph/CLI)
       normalized/*.json     # normalized model (list of resources/subresources)
   ```
7. **Sub‑resources:** Model child/feature resources (e.g., NIC IP configs, Private Endpoints’ private DNS zone links, NSG rules, Storage containers/Shares, Key Vault access policies/secrets, App Service auth settings, Route tables/routes, etc.).
8. **Settings coverage:** Capture TLS, identities, RBAC, locks, diagnostic settings, private endpoints, firewall rules, networking, auth, app settings, and SKU/perf knobs.
9. **Naming:** Use input‑driven prefixes/suffixes. Preserve existing Azure names unless the user asked to rename (they did not).
10. **Documentation:** At the top of each `main.tf`, add a short comment block explaining design choices, AVM mappings, and any unavoidable `azurerm_*` usage.

---

## Required Tools (MCP or equivalent)
- **`azure_resource_graph`** or **`azure_cli`** with `az graph`: enumerate resources
- **`azure_cli`**: fallbacks with `az resource list/show`, `az monitor diagnostic-settings list`, `az network private-endpoint list`, etc.
- **`microsoft_graph`**: resolve Entra ID objects referenced by app services, managed identities, role assignments when needed
- **`arm_export` (optional)**: export ARM JSON for certain resources to mine settings

If tools are available, Copilot must **use them directly** (no user interaction) and store payloads under `discovery/raw/`.

---

## Discovery Strategy (pseudocode)
1. **Load inputs** from `.copilot/azure-rg.inputs.json`:
   - `tenant_id`, `subscription_id`, `resource_group`, `location`, `out_dir`
   - optional filters (include/exclude by type), tag selectors
2. **ARG sweep** (preferred):
   - Query:  
     ```kusto
     Resources
     | where subscriptionId == '{subscription_id}'
     | where resourceGroup == '{resource_group}'
     | project id, name, type, kind, location, tags, properties, sku, identity, zones, managedBy
     ```
   - Save to `discovery/raw/arg-resources.json`.
3. **Deepen per resource type** (batched):
   - For each `type`, call the most specific `az ... show/list` or REST GETs to expand sub‑objects/settings (e.g., `diagnosticSettings`, `authSettingsV2`, `privateEndpointConnections`, `siteConfig`, `firewallRules`, `sslCertificates`, `ipConfigurations`, `routes`, `containers`, etc.).
   - Save each family payload under `discovery/raw/<type>-*.json`.
4. **Normalize** to a canonical model in `discovery/normalized/model.json` with parent/child relationships.
5. **AVM mapping**: For each normalized node, select an AVM module or `azurerm_*` fallback and produce a `plan.json` describing: target file, resource/module name, inputs, dependencies, and import ID.
6. **Synthesize Terraform** following the folder layout above.
7. **Generate `import.tf`**: one `import {}` per resource with the final address (e.g., `module.vnet.azurerm_subnet.this["subnetA"]`) and the Azure resource ID.

---

## Providers & Versions
- Lock providers in `versions.tf`: `azurerm >= 3.116`, `azuread >= 3.x`, `random`, `time`, and any AVM requirements.
- In `env/main.tf`, configure:
  - `provider "azurerm" { features {} subscription_id = var.subscription_id tenant_id = var.tenant_id }`
  - Optionally `provider "azuread"` when needed.
  - `data "azurerm_resource_group" "this"` for the target RG.

---
## Import Blocks
- Emit one `import {}` block per created resource, using the provider’s canonical ID format
- ensure that the to: address matches the generated resource/module name
- check the AVM docs for any special import syntax
- check the AVM GitHub to ensure that the import to: usage is correct (e.g., `module.<mod>.azurerm_<res>.<name>`, or `module.<mod>.azurerm_<res>.<name>["<key>"]` for maps/sets)
- For `azurerm_*` resources, use the standard `azurerm_<res>.<name>` format
- Order imports by resource type alphabetically, then by name
- Ensure that sub resources are imported after their parents and with the correct hierarchical address (e.g., `module.vnet.azurerm_subnet.this["subnetA"]`)

---

## Import ID Rules (examples)
- Generic: the **`id`** from discovery payload is authoritative.
- Subscriptions, RGs: `/subscriptions/<sub>/resourceGroups/<rg>`
- Subnets: `${azurerm_virtual_network.vnet.id}/subnets/<name>`
- Private DNS zone links: `${azurerm_private_dns_zone.this.id}/virtualNetworkLinks/<name>`
- App Service slot: `${azurerm_linux_web_app.app.id}/slots/<slot>`
- KV secret: `${azurerm_key_vault.kv.id}/secrets/<name>`

Document any tricky edge cases inline above the import block.

---

## Output Contract
Copilot must return **all files’ contents** ready to write to disk, plus a compact summary of discovered resources and the AVM mapping table it used. Do not ask follow‑ups. If tools were missing, prepend “TOOLLESS MODE” in the summary and include a `scripts/pull-discovery.sh` the user can run later.
