# GitHub Copilot Chat — **Instructions** for End‑to‑End Azure RG → Terraform (AVM‑first)

> **Purpose:** Enable Copilot Chat (VS Code) to scan an Azure Resource Group, recursively enumerate resources/sub‑resources + settings, then **generate complete Terraform** using **Azure Verified Modules (AVM) first**, falling back to `azurerm_*` only when no AVM exists, and finally emit **`import` blocks** for every discovered object. The flow is **non‑interactive**: Copilot should execute the entire prompt without asking questions.

---

## 🔒 Hard Rules

1. **Execute end‑to‑end without asking questions.** No confirmations, no “proceed?” prompts.
2. **Never run shell commands yourself.** Use Dev tools exposed to Copilot (MCP tools, Azure Tools/Graph, file I/O). If a required tool is unavailable, **report the missing tool and continue generation from available data** (e.g., previously exported JSON in workspace) rather than pausing.
3. **All inputs come from** `.copilot/azure-rg.inputs.json`. Do **not** infer or ask for values that are absent; use sane defaults described below.
4. **AVM‑first:** For each Azure resource, prefer a **stable official AVM module** (e.g., `Azure/avm-res-*`). If none exists, emit provider resources from `hashicorp/azurerm`.
5. **One pass, fully deterministic:** Work on an in‑memory plan then write files once. The output must be complete and consistent across runs for the same inputs.
6. **Resource group is data-only:** Never create the RG. Always reference it via `data.azurerm_resource_group.rg`.
7. **Idempotent code:** Use variable‑driven names and avoid hard‑coding subscription/tenant IDs in module code.
8. **Emit **`import` blocks** for **every** managed object corresponding to AVM modules or provider resources.
9. **File writes:** Only write inside `<target_path>` from inputs. Use this exact pattern:
   ```
   Create: <RELATIVE\WINDOWS\OR\POSIX\PATH\FILENAME>
   ```hcl
   # file contents
   ```
10. **No secrets in code.** If an existing secret value is discovered, reference Key Vault/variables and document in README.
11. **Formatting:** Run `terraform fmt` locally is user’s job; you only ensure canonical structure and style in emitted code.
12. **Do not scaffold CI/CD files unless requested in inputs.**

---

## ✅ Required Tools & Capabilities (must be available to Copilot)

Copilot must be able to use **at least one** of the following discovery surfaces. Use them **in this priority** and degrade gracefully if a surface is unavailable:

1. **Azure Resource Graph (ARG)** via a Copilot tool (e.g., MCP/extension) that supports Kusto‑like queries.
2. **ARM/Management API** read (GET) for resource details & child collections (again via a Copilot tool).
3. **Azure Tools API in VS Code** (workspace tree access programmatically) if exposed to Copilot.
4. **Fallback:** Parse pre‑exported JSON inventory files in the workspace (paths provided in inputs).

> If none are available, still generate a valid Terraform **skeleton** with TODOs and import scaffolding placeholders, listing the missing tools at the top of the README.

---

## 📥 Inputs File

Copilot must load: **`.copilot/azure-rg.inputs.json`** (UTF‑8). Example schema:

```jsonc
{
  // Required
  "subscriptionId": "00000000-0000-0000-0000-000000000000",
  "tenantId": "00000000-0000-0000-0000-000000000000",
  "resourceGroup": "rg-example-prod-001",
  "targetPath": "out/rg-example",

  // Optional discovery sources (in priority order)
  "discovery": {
    "prefer": ["arg", "arm", "azureTools", "workspaceJson"],
    "workspaceJsonGlobs": [
      "inventory/**/*.json",
      "snapshots/**/*.json"
    ]
  },

  // Terraform options
  "terraform": {
    "backend": {
      "type": "azurerm",
      "resource_group_name": "rg-tfstate-prod-001",
      "storage_account_name": "sttfstateprod001",
      "container_name": "tfstate",
      "key": "rg-example.terraform.tfstate"
    },
    "providers": {
      "azurerm": {
        "features": {},
        "subscription_id": "${var.subscription_id}",
        "tenant_id": "${var.tenant_id}"
      }
    },
    "moduleRegistry": "github.com/Azure",        // default AVM source host
    "allowCommunityAvm": false                   // if true, allow community AVMs when official not found
  },

  // Code style
  "naming": {
    "prefix": "ex",
    "environment": "prod",
    "location": "australiaeast"
  },

  // Optional extras
  "emitReadme": true,
  "emitExamples": true,
  "emitVariablesWithDefaults": false,
  "emitCi": false
}
```

**Assumptions:** If `terraform.backend` is omitted, emit a local backend with a prominent README warning. If `providers.azurerm.subscription_id/tenant_id` use `${var.*}`, emit corresponding `variables.tf` with `validation` blocks.

---

## 🧭 Discovery Algorithm (what Copilot must do)

1. **Load inputs** and set `<target_path>`.
2. **Discover inventory** (in order of preference):
   - **ARG**: `Resources | where resourceGroup == '<RG>' | project id, name, type, location, kind, sku, properties, tags`.
   - **ARM GET**: For each `id`, download full `GET` including `properties` and enumerate **child collections** (diagnostics, private endpoints, auth settings, subresources).
   - **Azure Tools**: If available, traverse tree and query details.
   - **Workspace JSON**: Merge files into a normalized inventory shape.
3. **Normalize** every item to:
   ```json
   { "id": "", "name": "", "type": "", "apiVersion": "", "location": "", "tags": {}, "sku": {}, "identity": {}, "properties": { ... }, "children": [ ... ] }
   ```
4. **Map to AVM or provider** using a mapping table (maintain in‑prompt, see below). If **AVM**:
   - Emit one **module block** per top‑level resource; nest subresources as inputs/child modules when supported.
   - If no input exists for a discovered feature, note in README and add a **`# TODO`** comment.
5. **Provider fallback** for unsupported/edge resources:
   - Use the closest `azurerm_*` resource(s).
   - Preserve settings from `properties` and `identity` as inputs.
6. **Emit imports**: For each module/resource produce an `import` block with the correct **resource address** and **Azure resource ID**.
7. **Cross‑resource wiring**: Express dependencies with `depends_on` sparingly; prefer implicit references (IDs/outputs).

---

## 📚 Minimal AVM Mapping Hints (extend as needed)

- Resource Group → **data source only** (`data.azurerm_resource_group`).
- **Key Vault** → `Azure/avm-res-keyvlt-vault` (vault, access policies/role assignments via inputs).
- **Storage Account** → `Azure/avm-res-stor-storageaccount` (containers, file shares as child modules/inputs).
- **Virtual Network** → `Azure/avm-res-network-virtualnetwork` (subnets, NSGs, UDRs as child inputs).
- **Public IP** → `Azure/avm-res-network-publicipaddress`.
- **LB / AppGW** → `Azure/avm-res-network-*` variants.
- **Private DNS Zone** → `Azure/avm-res-privatedns-zone` + `virtualNetworkLinks`.
- **Web App / Function / Plan** → `Azure/avm-res-web-*` modules where available.
- **Key resources not yet AVM’d** → fallback to `azurerm_*` and document.

> If an exact AVM name cannot be confirmed, emit a clear TODO and fallback provider resources so that the plan is runnable.

---

## 🏗️ Terraform Output Structure (what to write)

Within `<target_path>` create these files at minimum:

- `providers.tf` — `azurerm` + `random` + `time` providers (as needed)
- `backend.tf` — backend config (or local with warning)
- `variables.tf` — `subscription_id`, `tenant_id`, `location`, naming inputs
- `data.tf` — `data.azurerm_client_config`, `data.azurerm_resource_group.rg`
- `main.tf` — AVM modules + provider resources (grouped by service)
- `imports.tf` — **all** `import` blocks
- `outputs.tf` — ids, names, endpoints
- `README.md` — what was generated, gaps/TODOs, how to run `terraform init/plan/import`
- `examples/…` — optional examples if requested

---

## 🧾 Import Addressing Rules

- For AVM modules, the import address uses the module resource’s **internal resource address** as documented by the AVM (document in comments if ambiguous).
- For `azurerm_*` resources, use `azurerm_<type>.<name>`.
- Always import using the **full Azure resource ID** (e.g., `/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<name>`).

---

## 🧪 Validation

- Ensure generated HCL passes `terraform validate` in principle (provider versions pinned, no unsatisfied references).
- Use canonical HCL style: sorted blocks, consistent indentation, snake_case variable names.

---

## 📝 Reporting

At the top of `README.md`, include:
- Which discovery surface was used and which were missing.
- Count of resources discovered vs. mapped to AVM vs. provider fallback.
- A list of TODOs for unsupported sub-settings.

---

## 🚫 Safety / Privacy

- Do not exfiltrate secrets/connection strings. Replace with variable references and instructions to fetch via Key Vault.
- Redact GUIDs if requested via inputs.

---

## ❗If Tools Are Missing

Continue and generate a best‑effort Terraform skeleton using the inputs and any workspace JSON. List missing tools prominently in README.