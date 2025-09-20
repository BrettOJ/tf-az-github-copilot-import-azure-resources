# Prompt — **Scan Azure RG → Generate Terraform (AVM‑first) + Imports**
**Inputs file:** `.copilot/azure-rg.inputs.json` (required)  
**Do not ask questions. Execute the plan below end‑to‑end inside this response.**
**Use the instructions document in this repository under:** `.github\instructions\azure-rg-to-terraform-instructions-v2.instructions.md` (required)

## 0) Load Inputs
Read `.copilot/azure-rg.inputs.json` and set:
- `tenant_id`, `subscription_id`, `resource_group`, `location`, `targetPath` (default: `azure-tf-from-rg`)
- Optional: `include_types[]`, `exclude_types[]`, `tag_selector`, `name_prefix`, `avm_preferred[]`

If file missing: operate in **TOOLLESS MODE** and proceed with empty discovery, but still scaffold the project structure and a `scripts/pull-discovery.sh` that a human can run later.

## 1) Tool Check
Attempt to use MCP tools in this order (no user interaction):
1. `azure_resource_graph.query`
2. `azure_cli.exec`
3. `microsoft_graph.call` (only if needed for Entra references)

If none are available, set a flag `toolless = true`.

## 2) Discovery
When `toolless == false`:
- ARG query all resources in `{subscription_id}`, RG = `{resource_group}`:
  ```kusto
  Resources
  | where subscriptionId == '{subscription_id}'
  | where resourceGroup == '{resource_group}'
  | project id, name, type, kind, location, tags, properties, sku, identity, zones, managedBy
  ```
- Paginate if needed. Save raw JSON to `discovery/raw/arg-resources.json`.
- For each resource type present, gather deep settings using `az`:
  - Examples:  
    - App Service: `az webapp show`, `az webapp config appsettings list`, `az monitor diagnostic-settings list --resource <id>`  
    - Storage: `az storage account show`, enumerate containers/shares/queues/tables; diagnostic settings; private endpoints  
    - VNet: vnet, subnets, NSGs (rules), route tables (routes), DNS links, PE endpoints  
    - Key Vault: access policies (or RBAC), secrets (names only), private endpoints, diagnostic settings  
    - Databases: servers, DBs, firewall rules, AAD admins, connection policies  
    - Identity: user‑assigned identities details
- Normalize to `discovery/normalized/model.json` with parent/child relationships and computed import IDs.

When `toolless == true`:
- Create placeholders: `discovery/raw/README.md` describing how to run `scripts/pull-discovery.sh` to populate discovery data.

## 3) AVM Mapping
Build a mapping table `{ azure_type → module or azurerm_* }`. Examples to prioritize:
- `Microsoft.Network/virtualNetworks` → `Azure/avm-res-network-virtualnetwork`
- `Microsoft.Network/networkSecurityGroups` → `Azure/avm-res-network-networksecuritygroup`
- `Microsoft.Network/privateDnsZones` → `Azure/avm-res-network-privatednszone`
- `Microsoft.ContainerRegistry/registries` → `Azure/avm-res-containerregistry-registry`
- `Microsoft.Web/sites` (Linux) → `Azure/avm-res-appservice-linuxwebapp`
- `Microsoft.KeyVault/vaults` → `Azure/avm-res-keyvault-vault`
- `Microsoft.Storage/storageAccounts` → `Azure/avm-res-storage-storageaccount`
If no AVM exists, select the exact `azurerm_*` resource(s) to cover the configuration. Record rationale inline.

## 4) Synthesize Terraform
Create the folder layout under `{targetPath}` exactly as per **Instructions**. Populate:
- `env/versions.tf` with provider pins
- `env/main.tf` with providers and RG data source
- `env/variables.tf`, `env/locals.tf`, `env/outputs.tf`
- One folder per service family under `env/<service>/` with `main.tf` (+ minimal `variables.tf`, `outputs.tf`)
- `imports/import.tf` with **all** import blocks
- `discovery/` with raw and normalized payloads (or placeholders in TOOLLESS MODE)
- `README.md` explaining how to `terraform init` and `terraform plan`

### Required Practices
- Keep names & tags from Azure unless unsafe for Terraform
- Reference parent IDs rather than duplicating strings
- Generate `for_each` structures for collections (subnets, rules, containers)
- Generate variables only for values that must vary; prefer `locals` for discovered constants
- For every resource created, emit an `import {}` with the final address and Azure resource ID

## 5) Output
Return **every file’s content** as create‑file blocks ready to write to disk, PLUS:
- A compact **inventory summary** (count by type)
- The **AVM mapping table** used
- A one‑line **plan** for applying (`terraform init && terraform plan`) and importing (`terraform plan -generate-config-out` if desired + `terraform apply -refresh-only=false`)

> Do not ask questions. If any step fails internally, continue with partial results and note the gaps clearly.
