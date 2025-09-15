# Azure RG ➜ Terraform — Guardrails & Detailed Guidance

## Agent conduct
- Work **read-only** against Azure: discovery only.
- Always show your assumptions. If any required attribute is unknown, either query again or leave a `TODO` with a clear CLI to fetch it.
- Prefer **Azure Verified Modules (AVM)** when viable; otherwise use `azurerm_*`. Note that **imports must target the actual resource address**. When using AVM, you may need to:
  - Import to a **module child resource address** like `module.stg.azurerm_storage_account.this` if the module exposes a stable name, **or**
  - Generate the import block as a **comment** with guidance if the child address is not externally stable. In such cases, offer a fallback using direct `azurerm_*` resources.

## Discovery via Azure MCP Server
- Use the **Azure MCP Server** tools in VS Code Agent Mode:
  - Use the **Azure CLI Extension** tool to run:
    - `az account show` / `az account list` to resolve `subscription_id`
    - `az account set --subscription <id>`
    - `az resource list -g <resource_group> --output json`
  - Enrich as needed per type (examples):
    - VNets: `az network vnet show -g <rg> -n <vnet>`
    - Subnets: `az network vnet subnet list -g <rg> --vnet-name <vnet>`
    - Storage: `az storage account show -g <rg> -n <name>`
    - Web Apps / Plans: `az webapp show ...`, `az appservice plan show ...`
- Capture for each resource:
  - `id`, `name`, `type`, `location`, `tags`, and **required attributes** for TF (address spaces, SKUs, tier/size, replicas, version, identity, etc.).

## Terraform generation standards
- `versions.tf`:
  ```hcl
  terraform {
    required_version = ">= 1.5.0"
    required_providers {
      azurerm = {
        source  = "hashicorp/azurerm"
        version = "~> 3.113"
      }
    }
  }
