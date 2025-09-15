---
mode: agent
description: Scan an Azure resource group via Azure MCP Server and generate Terraform + import blocks (AVM preferred, azurerm fallback).
---

# Azure RG ➜ Terraform (code + imports)

[Load detailed rules & mappings](../instructions/azure-rg-to-terraform.instructions.md)

## What you will do
You will:
1) Discover all resources in an Azure **resource group** (and optionally filter providers) using the **Azure MCP Server** tools.
2) Generate a **Terraform** scaffold that prefers **Azure Verified Modules (AVM)** where available, otherwise falls back to `azurerm_*` resources.
3) Emit **config-driven `import` blocks** for *every* discovered resource, including the **`to`** address and **`id`** (full Azure resource ID).
4) Write files into a new folder and explain how to run `terraform plan` to validate imports (no destructive actions).

## Inputs (ask me if missing)
- **subscription_id**: Azure subscription GUID (or name you can resolve)
- **resource_group**: Target resource group name
- **target_path** (optional, default `infra/${resource_group}`): Where to place the generated Terraform
- **providers_filter** (optional): Array of Azure resource `type` prefixes to include (e.g., `["Microsoft.Network", "Microsoft.Storage"]`)
- **prefer_avm** (optional, default `true`): Prefer AVM modules when available
- **tf_required_version** (optional, default `>= 1.5.0`)
- **azurerm_version** (optional, default `~> 3.113`)
- **location_fallback** (optional): Use if location isn’t resolvable from ARM
- **name_prefix** (optional): Prefix for resource names in Terraform

## Tooling constraints
- **Prefer the Azure MCP Server tools** to fetch resource metadata (IDs, types, props). If tools are available, use them; otherwise explain what’s missing and provide equivalent `az` commands.
- For discovery, you may leverage either:
  - An Azure **resource listing** via MCP (e.g., Azure CLI extension tool to run `az resource list -g <rg>`), or
  - Specific MCP tools (e.g., *Resource Groups*, *Subscription*, *Azure CLI Extension*) to enumerate and enrich resources.
- Never mutate cloud resources. Read-only queries only.

## Discovery steps (strict)
1. Ensure you have **subscription context** and **resource group**. If `subscription_id` is a human name, resolve the GUID using MCP tools. Set the subscription for subsequent calls.
2. List **all resources** in the resource group, collecting at minimum: `id`, `name`, `type`, `location`, `tags`, and any **critical properties** required by Terraform/AVM (e.g., address spaces for VNets, SKU for Storage, Service Plan for Web Apps, etc.).
3. For resources whose essential attributes aren’t present in the generic list, make targeted lookups (e.g., `az network vnet show -g <rg> -n <name>` via the Azure CLI MCP tool).
4. Build an internal map of **ARM type ➜ Terraform resource / AVM module** candidates. Prefer AVM when there’s a clear, well-supported module; otherwise choose the closest `azurerm_*` resource.

## Generation rules (strict)
- Create/overwrite files under `${target_path}`:
  - `versions.tf` – `terraform` + `required_providers` with pinned versions.
  - `providers.tf` – `azurerm` provider (no features required by default).
  - `main.tf` – All resources (AVM modules or `azurerm_*`) with sane **minimal config** that matches discovered state. Factor common inputs (location, RG) via `data "azurerm_resource_group"` and locals.
  - `imports.tf` – One `import { to = ..., id = ... }` per discovered object. If a resource is declared via AVM, import to the **module child resource address** as appropriate (or provide the module-compatible import guidance as comments if direct import address isn’t feasible).
  - `variables.tf` – Inputs for subscription, location (optional), naming prefix, and any variables you require.
  - `outputs.tf` – Helpful IDs/names.
  - `README.md` – What you did, how to `init/plan`, notes on any manual follow-ups.
- **Resource addresses**:
  - For `azurerm_*` use `resource "azurerm_xxx" "<normalized_name>"`.
  - For AVM, declare `module "<normalized_name>" { source = "Azure/<module>/azurerm" ... }` and note import address guidance (see instructions link above).
- **Import blocks**:
  - Always emit `import` blocks **next to** the matching config within the same module/workspace.
  - Format:
    ```hcl
    import {
      to = <RESOURCE ADDRESS>
      id = "<ARM ID>"
    }
    ```
- **Relationships**:
  - Preserve references (e.g., subnets use `virtual_network_name` or `resource_id(...)` functions), avoid hardcoding where possible.
- **Safety**:
  - No deletes. Do not propose `destroy` operations. If config diverges from real state, instruct me to fix attributes until `plan` is zero-change.

## Mapping hints
When selecting AVM vs `azurerm_*`, prioritize stable modules:
- **Microsoft.Network/virtualNetworks** → `azurerm_virtual_network` (+ `azurerm_subnet`) or AVM network modules
- **Microsoft.Storage/storageAccounts** → `azurerm_storage_account` or AVM storage
- **Microsoft.ContainerRegistry/registries** → `azurerm_container_registry`
- **Microsoft.ContainerService/managedClusters** → `azurerm_kubernetes_cluster` (AKS)
- **Microsoft.KeyVault/vaults** → `azurerm_key_vault`
- **Microsoft.Web/serverfarms** + `sites` → `azurerm_service_plan`, `azurerm_linux_web_app` / `azurerm_windows_web_app`
- **Microsoft.DBforPostgreSQL/flexibleServers** → `azurerm_postgresql_flexible_server`
(Use az CLI/MCP lookups for child collections like subnets, access policies, app settings, etc.)

## Output format (strict)
- Write the files into the workspace at `${target_path}`.
- Show a **single consolidated diff/patch** of all files you created/updated.
- Then show a compact **runbook**:
  1. `cd ${target_path}`
  2. `terraform init`
  3. `terraform plan` (confirm the imports show up; fix drift if needed)
  4. `terraform apply` (only when plan is zero-change)

## Example final section in README.md
- List any resources **skipped** (unsupported mappings). For each, include the CLI you used to get details and your suggestion for a future mapping.
- If AVM import requires module-internal addresses, print examples and links to the right module docs.

## If tools are missing
- If the **Azure MCP Server** isn’t connected or the tool list is empty, say so explicitly and:
  - Provide the exact `az` CLI commands to run manually (copy-paste ready).
  - Continue generation using the data I provide back (I can paste JSON).
