---
mode: agent
description: Deep-scan ALL Azure resources in a resource group via Azure MCP Server and generate Terraform + import blocks using AVM modules by default (strict AVM-first), azurerm fallback only if no AVM exists, AzAPI for unknowns.
---

# Azure RG ➜ Terraform (ALL resources + sub-resources, **AVM-first**)

[Load detailed rules & mappings](..\\instructions\\azure-rg-to-terraform.instructions.md)

## Input Resolution (must do in this exact order)
You will resolve inputs using this algorithm:

1) Read the inline `${input:...}` values below. If a value is **not** `__auto__`, use it.
2) If a value **is** `__auto__`, check whether a JSON file is attached in chat context (e.g., via the paperclip or `#file:.copilot/azure-rg.inputs.json`).  
   - If present, **parse it** and use the value from the JSON if available.
3) If still `__auto__` after step 2, compute a sane default **only where noted** below; otherwise **ask me once** for the missing value.

> Example JSON schema:
> ```json
> {
>   "subscription_id": "00000000-0000-0000-0000-000000000000",
>   "resource_group": "rg-fitcoach-prod",
>   "target_path": "infra\\rg-fitcoach-prod",
>   "providers_filter": [],
>   "prefer_avm": true,
>   "avm_enforcement": "strict",
>   "tf_required_version": ">= 1.6.0",
>   "azurerm_version": "~> 3.113",
>   "azapi_version": "~> 1.13",
>   "location_fallback": "southeastasia",
>   "name_prefix": "fitcoach",
>   "include_subresources": true,
>   "subresource_depth": "all",
>   "api_version_strategy": "latest"
> }
> ```

## Inputs (every one has a sentinel default to avoid Copilot prompts)
- **subscription_id**: ${input:subscription_id:__auto__}  <!-- required, no computed default -->
- **resource_group**: ${input:resource_group:__auto__}    <!-- required, no computed default -->
- **target_path**: ${input:target_path:__auto__}          <!-- if __auto__, compute as `infra\\<resource_group>` -->
- **providers_filter** (JSON array): ${input:providers_filter:__auto__}  <!-- if __auto__, default to [] -->
- **prefer_avm**: ${input:prefer_avm:__auto__}            <!-- if __auto__, default to true -->
- **avm_enforcement** (`strict|relaxed`): ${input:avm_enforcement:__auto__}  <!-- if __auto__, default to strict -->
- **tf_required_version**: ${input:tf_required_version:__auto__}   <!-- if __auto__, default to >= 1.5.0 -->
- **azurerm_version**: ${input:azurerm_version:__auto__}           <!-- if __auto__, default to ~> 3.113 -->
- **azapi_version**: ${input:azapi_version:__auto__}               <!-- if __auto__, default to ~> 1.13 -->
- **location_fallback**: ${input:location_fallback:__auto__}       <!-- optional -->
- **name_prefix**: ${input:name_prefix:__auto__}                   <!-- optional -->
- **include_subresources**: ${input:include_subresources:__auto__} <!-- if __auto__, default to true -->
- **subresource_depth** (`basic|network|all`): ${input:subresource_depth:__auto__}  <!-- if __auto__, default to all -->
- **api_version_strategy** (`latest|stable`): ${input:api_version_strategy:__auto__} <!-- if __auto__, default to latest -->

> After resolving:
> - If `subscription_id` or `resource_group` remain `__auto__`, ask me **once** for those two values only.
> - If `target_path` is `__auto__`, set to `infra\\<resource_group>`.

## What you will do
1) Use **Azure MCP Server** tools to enumerate **all** resources in the target RG (any provider/namespace), then perform a **provider-driven child sweep** so ARM **sub-resources** are discovered (VNets→Subnets, NSGs→Rules, RTs→Routes, LBs→Rules/Probes, AppGW children, Private Endpoint DNS zone groups, etc.).
2) Generate **Terraform** with an **AVM-first** policy:
   - If an **AVM** module exists for a type, **use it**.
   - Else use **`azurerm_*`**.
   - If unknown/unsupported, use **`azapi_resource`** with `type@apiVersion`.
3) Emit **`import` blocks** for *every* object with **`to`** (Terraform address) and **`id`** (full ARM ID).
4) Write files under the final `target_path` (resolved above) and provide a runbook to validate with `terraform plan`.

## AVM-first enforcement
- Covered AVM types (must not default to `azurerm_*` unless justified): VNets/Subnets, NSGs/Rules, RouteTables/Routes, Private Endpoints/Zone groups, LBs (+children), App Gateways (+children), NAT Gateways, Public IPs, ACR, AKS, Key Vault, Storage, App Service Plan/Web Apps, Private DNS (+links/records).
- If enforcement mode is `strict`, **stop and ask** if any covered type is rendered as plain `azurerm_*` without justification.
- End with a summary: counts for AVM vs azurerm vs AzAPI, with justifications for any non-AVM in covered types.

## Tooling (read-only)
- Azure CLI via MCP: `az account list`, `az account set --subscription <id>`, `az resource list -g <rg> --output json`.
- ARM REST via MCP:
  - `GET /subscriptions/{sub}/providers?api-version=2021-04-01`
  - List each RG-scoped resourceType; for child types, iterate discovered parents to list children. Choose api-version based on `api_version_strategy`.
- If tools missing: print equivalent `az`/`az rest` commands; proceed with pasted JSON.

## Discovery algorithm
1. Resolve subscription; set context.
2. Generic sweep: `az resource list -g <rg>`.
3. Provider child sweep: enumerate provider types at RG scope; expand children (including multi-level).
4. Deduplicate by `id`; keep richest properties.
5. Normalize: `arm_id,name,type,location,tags,parent_id` + minimal TF-critical attrs; track cross-RG references.

## Terraform generation (AVM-first)
Create/overwrite under **`<target_path>`**:
- `versions.tf` (providers: azurerm, azapi with versions).
- `providers.tf` (`provider "azurerm" { features {} }`, `provider "azapi" {}`, data sources for subscription & RG, locals for location & name_prefix).
- `main.tf`
  - Prefer **AVM** module: `source = "Azure/<avm-module>/azurerm"`.
  - Else `azurerm_*`.
  - Else `azapi_resource`:
    ```hcl
    resource "azapi_resource" "<name>" {
      type      = "<Namespace/Type@<apiVersion>>"
      name      = "<name>"
      parent_id = "<parent ARM id or data.azurerm_resource_group.rg.id>"
      location  = local.location
      body      = {}
      lifecycle { ignore_changes = [body] }
    }
    ```
- `imports.tf` — one block per object:
  ```hcl
  import {
    to = <RESOURCE ADDRESS>
    id = "<FULL ARM ID>"
  }
