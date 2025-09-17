# tf-az-github-copilot-import-azure-resources
Project to test the importing of existing Azure resources using the GitHub Copilot Chat agents


# Original CHat GPT Prompt to create the copilot instructions and prompt

##### You said:

I want to use GtiHub copilot chat in Visual Studio code to connect to the Azure MCP server and scan resources that exist in a given resource group and then the prompt should create the terraform code to create the resources and also the import blocks including the to: and id: values for each resource. Please build a GitHub copilot promt.md and instructions.md file that I can use for this purpose

###### ChatGPT said:

Awesome—here are two ready-to-drop-in files that make Copilot Chat (in VS Code, agent mode) use the **Azure MCP Server** to enumerate resources in a resource group and then generate **Terraform** code **plus** `import { to = ..., id = ... }` blocks for each resource.

> Folder layout (recommended)
> 
> -   `.github/prompts/azure-rg-to-terraform.prompt.md`
>     
> -   `.github/instructions/azure-rg-to-terraform.instructions.md`
>     

___

### `.github/prompts/azure-rg-to-terraform.prompt.md`

```
<div><p>md</p><p><code id="code-lang-md"><span><span>---
mode: agent
<span>description: Scan an Azure resource group via Azure MCP Server and generate Terraform + import blocks (AVM preferred, azurerm fallback).
---</span>

</span><span><span># Azure RG ➜ Terraform (code + imports)</span></span><span>

[</span><span><span>Load detailed rules &amp; mappings</span></span><span>](</span><span><span>../instructions/azure-rg-to-terraform.instructions.md</span></span><span>)

</span><span><span>## What you will do</span></span><span>
You will:
1) Discover all resources in an Azure </span><span><span>**resource group**</span></span><span> (and optionally filter providers) using the </span><span><span>**Azure MCP Server**</span></span><span> tools.
2) Generate a </span><span><span>**Terraform**</span></span><span> scaffold that prefers </span><span><span>**Azure Verified Modules (AVM)**</span></span><span> where available, otherwise falls back to </span><span><span>`azurerm_*`</span></span><span> resources.
3) Emit </span><span><span>**config-driven `import` blocks**</span></span><span> for </span><span><span>*every*</span></span><span> discovered resource, including the </span><span><span>**`to`**</span></span><span> address and </span><span><span>**`id`**</span></span><span> (full Azure resource ID).
4) Write files into a new folder and explain how to run </span><span><span>`terraform plan`</span></span><span> to validate imports (no destructive actions).

</span><span><span>## Inputs (ask me if missing)</span></span><span>
</span><span><span>-</span></span><span> <span>**subscription<span>_id**: Azure subscription GUID (or name you can resolve)
- **resource_</span>group**</span>: Target resource group name
</span><span><span>-</span></span><span> </span><span><span>**target<span>_path** (optional, default `infra/${resource_</span></span></span><span>group}`): Where to place the generated Terraform
- **providers<span>_filter** (optional): Array of Azure resource `type` prefixes to include (e.g., `["Microsoft.Network", "Microsoft.Storage"]`)
- </span></span><span><span>**prefer_avm**</span></span><span> (optional, default `true`): Prefer AVM modules when available
- </span><span><span>**tf_required_version**</span></span><span> (optional, default `&gt;= 1.5.0`)
- </span><span><span>**azurerm_version**</span></span><span> (optional, default `~&gt; 3.113`)
- </span><span><span>**location_fallback**</span></span><span> (optional): Use if location isn’t resolvable from ARM
- </span><span><span>**name_prefix**</span></span><span> (optional): Prefix for resource names in Terraform

## Tooling constraints
- </span><span><span>**Prefer the Azure MCP Server tools**</span></span><span> to fetch resource metadata (IDs, types, props). If tools are available, use them; otherwise explain what’s missing and provide equivalent `az` commands.
- For discovery, you may leverage either:
  - An Azure </span><span><span>**resource listing**</span></span><span> via MCP (e.g., Azure CLI extension tool to run `az resource list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;`), or
  - Specific MCP tools (e.g., *Resource Groups*, *Subscription*, *Azure CLI Extension*) to enumerate and enrich resources.
- Never mutate cloud resources. Read-only queries only.

## Discovery steps (strict)
1. Ensure you have </span><span><span>**subscription context**</span></span><span> and </span><span><span>**resource group**</span></span><span>. If `subscription_id` is a human name, resolve the GUID using MCP tools. Set the subscription for subsequent calls.
</span><span><span>2.</span></span><span> List </span><span><span>**all resources**</span></span><span> in the resource group, collecting at minimum: </span><span><span>`id`</span></span><span>, </span><span><span>`name`</span></span><span>, </span><span><span>`type`</span></span><span>, </span><span><span>`location`</span></span><span>, </span><span><span>`tags`</span></span><span>, and any </span><span><span>**critical properties**</span></span><span> required by Terraform/AVM (e.g., address spaces for VNets, SKU for Storage, Service Plan for Web Apps, etc.).
</span><span><span>3.</span></span><span> For resources whose essential attributes aren’t present in the generic list, make targeted lookups (e.g., </span><span><span>`az network vnet show -g &lt;rg&gt; -n &lt;name&gt;`</span></span><span> via the Azure CLI MCP tool).
</span><span><span>4.</span></span><span> Build an internal map of </span><span><span>**ARM type ➜ Terraform resource / AVM module**</span></span><span> candidates. Prefer AVM when there’s a clear, well-supported module; otherwise choose the closest </span><span><span>`azurerm_*`</span></span><span> resource.

</span><span><span>## Generation rules (strict)</span></span><span>
</span><span><span>-</span></span><span> Create/overwrite files under </span><span><span>`${target_path}`</span></span><span>:
</span><span><span>  -</span></span><span> </span><span><span>`versions.tf`</span></span><span> – </span><span><span>`terraform`</span></span><span> + </span><span><span>`required_providers`</span></span><span> with pinned versions.
</span><span><span>  -</span></span><span> </span><span><span>`providers.tf`</span></span><span> – </span><span><span>`azurerm`</span></span><span> provider (no features required by default).
</span><span><span>  -</span></span><span> </span><span><span>`main.tf`</span></span><span> – All resources (AVM modules or </span><span><span>`azurerm_*`</span></span><span>) with sane </span><span><span>**minimal config**</span></span><span> that matches discovered state. Factor common inputs (location, RG) via </span><span><span>`data "azurerm_resource_group"`</span></span><span> and locals.
</span><span><span>  -</span></span><span> </span><span><span>`imports.tf`</span></span><span> – One </span><span><span>`import { to = ..., id = ... }`</span></span><span> per discovered object. If a resource is declared via AVM, import to the </span><span><span>**module child resource address**</span></span><span> as appropriate (or provide the module-compatible import guidance as comments if direct import address isn’t feasible).
</span><span><span>  -</span></span><span> </span><span><span>`variables.tf`</span></span><span> – Inputs for subscription, location (optional), naming prefix, and any variables you require.
</span><span><span>  -</span></span><span> </span><span><span>`outputs.tf`</span></span><span> – Helpful IDs/names.
</span><span><span>  -</span></span><span> </span><span><span>`README.md`</span></span><span> – What you did, how to </span><span><span>`init/plan`</span></span><span>, notes on any manual follow-ups.
</span><span><span>-</span></span><span> </span><span><span>**Resource addresses**</span></span><span>:
</span><span><span>  -</span></span><span> For </span><span><span>`azurerm_*`</span></span><span> use </span><span><span>`resource "azurerm_xxx" "&lt;normalized_name&gt;"`</span></span><span>.
</span><span><span>  -</span></span><span> For AVM, declare </span><span><span>`module "&lt;normalized_name&gt;" { source = "Azure/&lt;module&gt;/azurerm" ... }`</span></span><span> and note import address guidance (see instructions link above).
</span><span><span>-</span></span><span> </span><span><span>**Import blocks**</span></span><span>:
</span><span><span>  -</span></span><span> Always emit </span><span><span>`import`</span></span><span> blocks </span><span><span>**next to**</span></span><span> the matching config within the same module/workspace.
</span><span><span>  -</span></span><span> Format:
<span>    ```hcl
    import {
      to = &lt;RESOURCE ADDRESS&gt;
      id = "&lt;ARM ID&gt;"
    }
    ```
- **Relationships**:
  - Preserve references (e.g., subnets use `virtual_network_name` or `resource_id(...)` functions), avoid hardcoding where possible.
- **Safety**:
  - No deletes. Do not propose `destroy` operations. If config diverges from real state, instruct me to fix attributes until `plan` is zero-change.
</span>
</span><span><span>## Mapping hints</span></span><span>
When selecting AVM vs </span><span><span>`azurerm_*`</span></span><span>, prioritize stable modules:
</span><span><span>-</span></span><span> </span><span><span>**Microsoft.Network/virtualNetworks**</span></span><span> → </span><span><span>`azurerm_virtual_network`</span></span><span> (+ </span><span><span>`azurerm_subnet`</span></span><span>) or AVM network modules
</span><span><span>-</span></span><span> </span><span><span>**Microsoft.Storage/storageAccounts**</span></span><span> → </span><span><span>`azurerm_storage_account`</span></span><span> or AVM storage
</span><span><span>-</span></span><span> </span><span><span>**Microsoft.ContainerRegistry/registries**</span></span><span> → </span><span><span>`azurerm_container_registry`</span></span><span>
</span><span><span>-</span></span><span> </span><span><span>**Microsoft.ContainerService/managedClusters**</span></span><span> → </span><span><span>`azurerm_kubernetes_cluster`</span></span><span> (AKS)
</span><span><span>-</span></span><span> </span><span><span>**Microsoft.KeyVault/vaults**</span></span><span> → </span><span><span>`azurerm_key_vault`</span></span><span>
</span><span><span>-</span></span><span> </span><span><span>**Microsoft.Web/serverfarms**</span></span><span> + </span><span><span>`sites`</span></span><span> → </span><span><span>`azurerm_service_plan`</span></span><span>, </span><span><span>`azurerm_linux_web_app`</span></span><span> / </span><span><span>`azurerm_windows_web_app`</span></span><span>
</span><span><span>-</span></span><span> </span><span><span>**Microsoft.DBforPostgreSQL/flexibleServers**</span></span><span> → </span><span><span>`azurerm_postgresql_flexible_server`</span></span><span>
(Use az CLI/MCP lookups for child collections like subnets, access policies, app settings, etc.)

</span><span><span>## Output format (strict)</span></span><span>
</span><span><span>-</span></span><span> Write the files into the workspace at </span><span><span>`${target_path}`</span></span><span>.
</span><span><span>-</span></span><span> Show a </span><span><span>**single consolidated diff/patch**</span></span><span> of all files you created/updated.
</span><span><span>-</span></span><span> Then show a compact </span><span><span>**runbook**</span></span><span>:
</span><span><span>  1.</span></span><span> </span><span><span>`cd ${target_path}`</span></span><span>
</span><span><span>  2.</span></span><span> </span><span><span>`terraform init`</span></span><span>
</span><span><span>  3.</span></span><span> </span><span><span>`terraform plan`</span></span><span> (confirm the imports show up; fix drift if needed)
</span><span><span>  4.</span></span><span> </span><span><span>`terraform apply`</span></span><span> (only when plan is zero-change)

</span><span><span>## Example final section in README.md</span></span><span>
</span><span><span>-</span></span><span> List any resources </span><span><span>**skipped**</span></span><span> (unsupported mappings). For each, include the CLI you used to get details and your suggestion for a future mapping.
</span><span><span>-</span></span><span> If AVM import requires module-internal addresses, print examples and links to the right module docs.

</span><span><span>## If tools are missing</span></span><span>
</span><span><span>-</span></span><span> If the </span><span><span>**Azure MCP Server**</span></span><span> isn’t connected or the tool list is empty, say so explicitly and:
</span><span><span>  -</span></span><span> Provide the exact </span><span><span>`az`</span></span><span> CLI commands to run manually (copy-paste ready).
</span><span><span>  -</span></span><span> Continue generation using the data I provide back (I can paste JSON).
</span></span></code></p></div>
```

___

### `.github/instructions/azure-rg-to-terraform.instructions.md`

```
<div><p>md</p><p><code id="code-lang-md"><span><span><span># Azure RG ➜ Terraform — Guardrails &amp; Detailed Guidance</span></span><span>

</span><span><span>## Agent conduct</span></span><span>
</span><span><span>-</span></span><span> Work </span><span><span>**read-only**</span></span><span> against Azure: discovery only.
</span><span><span>-</span></span><span> Always show your assumptions. If any required attribute is unknown, either query again or leave a </span><span><span>`TODO`</span></span><span> with a clear CLI to fetch it.
</span><span><span>-</span></span><span> Prefer </span><span><span>**Azure Verified Modules (AVM)**</span></span><span> when viable; otherwise use </span><span><span>`azurerm_*`</span></span><span>. Note that </span><span><span>**imports must target the actual resource address**</span></span><span>. When using AVM, you may need to:
</span><span><span>  -</span></span><span> Import to a </span><span><span>**module child resource address**</span></span><span> like </span><span><span>`module.stg.azurerm_storage_account.this`</span></span><span> if the module exposes a stable name, </span><span><span>**or**</span></span><span>
</span><span><span>  -</span></span><span> Generate the import block as a </span><span><span>**comment**</span></span><span> with guidance if the child address is not externally stable. In such cases, offer a fallback using direct </span><span><span>`azurerm_*`</span></span><span> resources.

</span><span><span>## Discovery via Azure MCP Server</span></span><span>
</span><span><span>-</span></span><span> Use the </span><span><span>**Azure MCP Server**</span></span><span> tools in VS Code Agent Mode:
</span><span><span>  -</span></span><span> Use the </span><span><span>**Azure CLI Extension**</span></span><span> tool to run:
</span><span><span>    -</span></span><span> </span><span><span>`az account show`</span></span><span> / </span><span><span>`az account list`</span></span><span> to resolve </span><span><span>`subscription_id`</span></span><span>
</span><span><span>    -</span></span><span> </span><span><span>`az account set --subscription &lt;id&gt;`</span></span><span>
</span><span><span>    -</span></span><span> </span><span><span>`az resource list -g &lt;resource_group&gt; --output json`</span></span><span>
</span><span><span>  -</span></span><span> Enrich as needed per type (examples):
</span><span><span>    -</span></span><span> VNets: </span><span><span>`az network vnet show -g &lt;rg&gt; -n &lt;vnet&gt;`</span></span><span>
</span><span><span>    -</span></span><span> Subnets: </span><span><span>`az network vnet subnet list -g &lt;rg&gt; --vnet-name &lt;vnet&gt;`</span></span><span>
</span><span><span>    -</span></span><span> Storage: </span><span><span>`az storage account show -g &lt;rg&gt; -n &lt;name&gt;`</span></span><span>
</span><span><span>    -</span></span><span> Web Apps / Plans: </span><span><span>`az webapp show ...`</span></span><span>, </span><span><span>`az appservice plan show ...`</span></span><span>
</span><span><span>-</span></span><span> Capture for each resource:
</span><span><span>  -</span></span><span> </span><span><span>`id`</span></span><span>, </span><span><span>`name`</span></span><span>, </span><span><span>`type`</span></span><span>, </span><span><span>`location`</span></span><span>, </span><span><span>`tags`</span></span><span>, and </span><span><span>**required attributes**</span></span><span> for TF (address spaces, SKUs, tier/size, replicas, version, identity, etc.).

</span><span><span>## Terraform generation standards</span></span><span>
</span><span><span>-</span></span><span> </span><span><span>`versions.tf`</span></span><span>:
  <span>```hcl
  terraform {
    required_version = "&gt;= 1.5.0"
    required_providers {
      azurerm = {
        source  = "hashicorp/azurerm"
        version = "~&gt; 3.113"
      }
    }
  }
</span></span></span></code></p></div>
```

-   `providers.tf`:
    
    ```
    <div><p>hcl</p><p><code id="code-lang-hcl"><span>provider "azurerm" {
      features {}
    }
    
    data "azurerm_subscription" "current" {}
    data "azurerm_resource_group" "rg" {
      name = var.resource_group
    }
    
    locals {
      name_prefix = var.name_prefix != "" ? var.name_prefix : var.resource_group
      location    = try(data.azurerm_resource_group.rg.location, var.location_fallback)
    }
    </span></code></p></div>
    ```
    
-   `variables.tf` (minimum):
    
    ```
    <div><p>hcl</p><p><code id="code-lang-hcl"><span>variable "resource_group" { type = string }
    variable "name_prefix"    { type = string, default = "" }
    variable "location_fallback" { type = string, default = null }
    </span></code></p></div>
    ```
    
-   **Resource blocks**: populate only attributes required to match existing state, to avoid Terraform proposing replacements. Use references (e.g., `data.azurerm_resource_group.rg.name`) not literals where possible.
    
-   **Import blocks**:
    
    -   One per discovered object, adjacent to its config.
        
    -   Use the **full ARM ID** as `id`.
        
    -   Examples:
        
        ```
        <div><p>hcl</p><p><code id="code-lang-hcl"><span># Simple resource
        resource "azurerm_storage_account" "sa_main" { name = "mystgacct"  resource_group_name = data.azurerm_resource_group.rg.name  location = local.location  account_tier = "Standard" account_replication_type = "LRS" }
        
        import {
          to = azurerm_storage_account.sa_main
          id = "/subscriptions/&lt;subId&gt;/resourceGroups/&lt;rg&gt;/providers/Microsoft.Storage/storageAccounts/mystgacct"
        }
        </span></code></p></div>
        ```
        
        ```
        <div><p>hcl</p><p><code id="code-lang-hcl"><span># Import to a resource inside a module (when the module exposes a stable address)
        module "vnet_hub" {
          source              = "Azure/avm-res-network-virtualnetwork/azurerm"
          name                = "${local.name_prefix}-hub-vnet"
          resource_group_name = data.azurerm_resource_group.rg.name
          location            = local.location
          address_space       = ["10.10.0.0/16"]
        }
        
        # If the module's internal resource address is well-known:
        # import {
        #   to = module.vnet_hub.azurerm_virtual_network.this
        #   id = "/subscriptions/&lt;subId&gt;/resourceGroups/&lt;rg&gt;/providers/Microsoft.Network/virtualNetworks/&lt;name&gt;"
        # }
        #
        # If not guaranteed, comment the import and provide a fallback note in README.md.
        </span></code></p></div>
        ```
        

## AVM selection guidance

-   Choose AVM modules that:
    
    -   Are active and documented in the **AVM catalog**, and
        
    -   Expose predictable internal resource addresses where imports are feasible, **or** provide explicit guidance that import to the module is supported.
        
-   If in doubt for imports, fall back to first-party `azurerm_*` resources for the initial adoption; you can refactor to AVM post-import with `moved` blocks.
    

## Output & runbook (must include)

-   Render `versions.tf`, `providers.tf`, `main.tf`, `variables.tf`, `outputs.tf`, `imports.tf`, and a `README.md` with:
    
    -   How to run:
        
        ```
        <div><p>shell</p><p><code><span><span>terraform init
        terraform plan
        </span><span><span># </span></span><span><span id="code-lang-bash">ensure the plan shows only <span>'import'</span></span></span><span> actions and no creates/replaces
        terraform apply
        </span></span></code></p></div>
        ```
        
    -   Any **manual** lookups still required (copy-paste `az` commands).
        
    -   A list of **unsupported/omitted** resources and suggestions.
        

## Safety

-   Do **not** include `destroy` actions or replacements.
    
-   If an attribute mismatch would cause a replacement, add a comment and **do not** propose a default—ask the user to confirm the real value.
    

````
<div><p>pgsql</p><p><code><span><span>
</span><span><span>---</span></span><span>

### How </span><span><span>to</span></span><span> use </span><span><span>in</span></span><span> VS Code (quick)

</span><span><span>1</span></span><span>) **Ensure Azure MCP </span><span><span>Server</span></span><span> </span><span><span>is</span></span><span> connected** (VS Code → Copilot Chat → *Agent mode*). </span><span><span>If</span></span><span> you haven’t wired it up: </span><span><span>add</span></span><span> an MCP config </span><span><span>like</span></span><span> this </span><span><span>to</span></span><span> `.vscode/mcp.json`:

```</span><span><span>json</span></span><span>
{
  "servers": {
    "Azure MCP Server": {
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"]
    }
  }
}
</span></span></code></p></div>
````

Open Copilot Chat, switch to **Agent mode**, refresh tools, and you should see **Azure MCP Server** available. [GitHub](https://github.com/Azure/azure-mcp)

> Docs: VS Code supports MCP servers and prompt files; prompt files run directly in chat (paperclip → **Prompt…** → select your file). [Visual Studio Code+1](https://code.visualstudio.com/docs/copilot/customization/mcp-servers?utm_source=chatgpt.com)

2.  Drop both files into the folders shown above.
    
3.  In Copilot Chat (Agent mode), click the **paperclip → Prompt…**, choose `azure-rg-to-terraform.prompt.md`, and provide:
    
    -   `subscription_id`
        
    -   `resource_group`
        
    -   (optional) `providers_filter`, `target_path`, etc.
        

Copilot will use the **Azure MCP Server** tools to list resources and then generate the Terraform plus import blocks, using the `import { to = ..., id = ... }` syntax introduced in Terraform 1.5. [HashiCorp Developer](https://developer.hashicorp.com/terraform/language/import?utm_source=chatgpt.com)

___

### Notes & references

-   **Azure MCP Server** overview & tool capabilities (including the Azure CLI tool): the server exposes multiple Azure tools you can call from Copilot Agent mode. [GitHub+1](https://github.com/Azure/azure-mcp)
    
-   **Prompt files & instructions files** in VS Code: where to store them (`.github/prompts`, `.github/*instructions*.md`) and how to run them from chat. [Visual Studio Code+1](https://code.visualstudio.com/docs/copilot/customization/prompt-files?utm_source=chatgpt.com)
    
-   **Terraform import block** syntax (`to` and `id`) and guidance. [HashiCorp Developer](https://developer.hashicorp.com/terraform/language/import?utm_source=chatgpt.com)
    

If you’d like, I can also add a tiny example repo (with the folders pre-created) or tailor the mapping table for the specific Azure services you use most.

##### You said:

when I trigger this prompt in the copilot chat windows, how can I specify the inputs in a file - - \*\*subscription\_id\*\*: Azure subscription GUID (or name you can resolve) - \*\*resource\_group\*\*: Target resource group name - \*\*target\_path\*\* (optional, default `infra/${resource_group}`): Where to place the generated Terraform - \*\*providers\_filter\*\* (optional): Array of Azure resource `type` prefixes to include (e.g., `["Microsoft.Network", "Microsoft.Storage"]`) - \*\*prefer\_avm\*\* (optional, default `true`): Prefer AVM modules when available - \*\*tf\_required\_version\*\* (optional, default `>= 1.5.0`) - \*\*azurerm\_version\*\* (optional, default `~> 3.113`) - \*\*location\_fallback\*\* (optional): Use if location isn’t resolvable from ARM - \*\*name\_prefix\*\* (optional): Prefix for resource names in Terraform

###### ChatGPT said:

Great question—there are two clean ways to “feed” those inputs to a Copilot **prompt file** without retyping them each time:

## Option A — Pass args inline when you run the prompt

Prompt files support **input variables** like `${input:subscription_id}`. When you run a prompt you can append `key=value` pairs after a colon:

```
<div><p>bash</p><p><code><span><span>/azure-rg-to-terraform: subscription_id=00000000-0000-0000-0000-000000000000 resource_group=rg-fitcoach-prod target_path=infra/rg-fitcoach-prod providers_filter=[</span><span><span>"Microsoft.Network"</span></span><span>,</span><span><span>"Microsoft.Storage"</span></span><span>] prefer_avm=</span><span><span>true</span></span><span> tf_required_version=</span><span><span>"&gt;= 1.6.0"</span></span><span> azurerm_version=</span><span><span>"~&gt; 3.113"</span></span><span> location_fallback=southeastasia name_prefix=fitcoach
</span></span></code></p></div>
```

In your `.prompt.md`, reference them like:

```
<div><p>md</p><p><code id="code-lang-md"><span><span><span>## Inputs</span></span><span>
</span><span><span>-</span></span><span> subscription</span><span><span>_id: ${input:subscription_</span></span><span>id}
</span><span><span>-</span></span><span> resource</span><span><span>_group: ${input:resource_</span></span><span>group}
</span><span><span>-</span></span><span> target</span><span><span>_path: ${input:target_</span></span><span>path:infra/${input:resource<span>_group}}
- providers_</span>filter (JSON array): ${input:providers<span>_filter:["Microsoft.Network","Microsoft.Storage"]}
- prefer_</span>avm: ${input:prefer<span>_avm:true}
- tf_</span>required</span><span><span>_version: ${input:tf_</span></span><span>required<span>_version:&gt;= 1.5.0}
- azurerm_</span>version: ${input:azurerm<span>_version:~&gt; 3.113}
- location_</span>fallback: ${input:location<span>_fallback:southeastasia}
- name_</span>prefix: ${input:name<span>_prefix:}
</span></span></span></code></p></div>
```

VS Code’s docs show `${input:...}` variables and the `/promptName: key=value` syntax. [Visual Studio Code](https://code.visualstudio.com/docs/copilot/customization/prompt-files)

## Option B — Keep a reusable **inputs file** in your repo

If you prefer a file, add (for example) `.copilot/azure-rg.inputs.json`:

```
<div><p>json</p><p><code id="code-lang-json"><span><span><span>{</span></span><span>
  </span><span><span>"subscription_id"</span></span><span><span>:</span></span><span> </span><span><span>"00000000-0000-0000-0000-000000000000"</span></span><span><span>,</span></span><span>
  </span><span><span>"resource_group"</span></span><span><span>:</span></span><span> </span><span><span>"rg-fitcoach-prod"</span></span><span><span>,</span></span><span>
  </span><span><span>"target_path"</span></span><span><span>:</span></span><span> </span><span><span>"infra/rg-fitcoach-prod"</span></span><span><span>,</span></span><span>
  </span><span><span>"providers_filter"</span></span><span><span>:</span></span><span> </span><span><span>[</span></span><span><span>"Microsoft.Network"</span></span><span><span>,</span></span><span> </span><span><span>"Microsoft.Storage"</span></span><span><span>]</span></span><span><span>,</span></span><span>
  </span><span><span>"prefer_avm"</span></span><span><span>:</span></span><span> </span><span><span><span>true</span></span></span><span></span><span><span>,</span></span><span>
  </span><span><span>"tf_required_version"</span></span><span><span>:</span></span><span> </span><span><span>"&gt;= 1.6.0"</span></span><span><span>,</span></span><span>
  </span><span><span>"azurerm_version"</span></span><span><span>:</span></span><span> </span><span><span>"~&gt; 3.113"</span></span><span><span>,</span></span><span>
  </span><span><span>"location_fallback"</span></span><span><span>:</span></span><span> </span><span><span>"southeastasia"</span></span><span><span>,</span></span><span>
  </span><span><span>"name_prefix"</span></span><span><span>:</span></span><span> </span><span><span>"fitcoach"</span></span><span>
</span><span><span>}</span></span><span>
</span></span></code></p></div>
```

Then run the prompt while **attaching the file as context**:

1.  In the chat box, type:  
    `#file:.copilot/azure-rg.inputs.json`
    
2.  On the next line, run:  
    `/azure-rg-to-terraform`
    

And add a tiny stanza near the top of your prompt so the agent knows to use it if present:

```
<div><p>md</p><p><code id="code-lang-md"><span><span><span>&gt; If a JSON file named `.copilot/azure-rg.inputs.json` is attached in context, parse it and use those values as defaults. Inline `${input:...}` values (if provided) override the file.</span></span><span>
</span></span></code></p></div>
```

This uses VS Code’s “attach file as context” (`#file:`) capability and the prompt’s own instructions to read/merge values; there isn’t a built-in “auto-load JSON into variables,” so this pattern is the reliable, repeatable workflow. Docs for prompt files & variables are here. [Visual Studio Code](https://code.visualstudio.com/docs/copilot/customization/prompt-files)

___

### Bonus: make the prompt friendlier

-   Add helpful **placeholders**: `${input:resource_group:rg-example}` so Copilot shows a hint. [Visual Studio Code](https://code.visualstudio.com/docs/copilot/customization/prompt-files)
    
-   If you want this prompt to always run in **Agent mode** with your Azure MCP tools available, keep `mode: agent` and ensure your `.vscode/mcp.json` is configured (VS Code MCP docs). [Visual Studio Code](https://code.visualstudio.com/docs/copilot/customization/mcp-servers?utm_source=chatgpt.com)
    

If you want, I can patch your existing `azure-rg-to-terraform.prompt.md` to include the `${input:...}` variables and the JSON-loader hint so you can drop it in and go.

##### You said:

patch your existing azure-rg-to-terraform.prompt.md to include the ${input:...} variables and the JSON-loader hint so Ican drop it in and go.

###### ChatGPT said:

Perfect—here’s a drop-in replacement for **`.github/prompts/azure-rg-to-terraform.prompt.md`** with `${input:...}` variables wired up and a JSON-loader hint so you can keep a reusable inputs file.

> Save this as: `.github/prompts/azure-rg-to-terraform.prompt.md`

```
<div><p>md</p><p><code id="code-lang-md"><span><span>---
mode: agent
<span>description: Scan an Azure resource group via Azure MCP Server and generate Terraform + import blocks (AVM preferred, azurerm fallback).
---</span>

</span><span><span># Azure RG ➜ Terraform (code + imports)</span></span><span>

[</span><span><span>Load detailed rules &amp; mappings</span></span><span>](</span><span><span>../instructions/azure-rg-to-terraform.instructions.md</span></span><span>)

</span><span><span>## Configuration source order (highest precedence first)</span></span><span>
</span><span><span>1.</span></span><span> </span><span><span>**Inline inputs**</span></span><span> provided when running the prompt (e.g. </span><span><span>`/azure-rg-to-terraform: subscription_id=... resource_group=...`</span></span><span>), referenced via </span><span><span>`${input:...}`</span></span><span> below.
</span><span><span>2.</span></span><span> If a </span><span><span>**JSON file**</span></span><span> named </span><span><span>`.copilot/azure-rg.inputs.json`</span></span><span> is attached as chat context (use </span><span><span>`#file:.copilot/azure-rg.inputs.json`</span></span><span>), </span><span><span>**parse it**</span></span><span> and use keys as defaults for any inputs not provided inline.
</span><span><span>3.</span></span><span> If anything is still missing, ask me interactively.

</span><span><span>&gt; Expected JSON shape (example):</span></span><span>
</span><span><span>&gt; ```json</span></span><span>
</span><span><span>&gt; {</span></span><span>
<span>&gt;   "subscription<span>_id": "00000000-0000-0000-0000-000000000000",
&gt;   "resource_</span>group": "rg-fitcoach-prod",</span>
<span>&gt;   "target<span>_path": "infra/rg-fitcoach-prod",
&gt;   "providers_</span>filter": ["Microsoft.Network","Microsoft.Storage"],</span>
<span>&gt;   "prefer<span>_avm": true,
&gt;   "tf_</span>required<span>_version": "&gt;= 1.6.0",
&gt;   "azurerm_</span>version": "~&gt; 3.113",</span>
<span>&gt;   "location<span>_fallback": "southeastasia",
&gt;   "name_</span>prefix": "fitcoach"</span>
</span><span><span>&gt; }</span></span><span>
</span><span><span>&gt; ```</span></span><span>

</span><span><span>## Inputs (resolved via `${input:...}`; fall back to the JSON file when present)</span></span><span>
</span><span><span>-</span></span><span> </span><span><span>**subscription<span>_id**: ${input:subscription_</span></span></span><span>id}
- **resource<span>_group<span>**: ${input:resource_group}
- **</span>target_</span>path** (default </span><span><span>`infra/${input:resource_group}`</span></span><span>): ${input:target</span><span><span>_path:infra/${input:resource_</span></span><span>group}}
</span><span><span>-</span></span><span> </span><span><span>**providers<span>_filter** (JSON array; default `[]`): ${input:providers_</span></span></span><span>filter:[]}
- **prefer</span><span><span>_avm** (default `true`): ${input:prefer_</span></span><span>avm:true}
</span><span><span>-</span></span><span> </span><span><span>**tf<span>_required_</span></span></span><span>version** (default </span><span><span>`&gt;= 1.5.0`</span></span><span>): ${input:tf</span><span><span>_required_</span></span><span>version:&gt;= 1.5.0}
</span><span><span>-</span></span><span> </span><span><span>**azurerm<span>_version** (default `~&gt; 3.113`): ${input:azurerm_</span></span></span><span>version:~&gt; 3.113}
- **location</span><span><span>_fallback** (optional): ${input:location_</span></span><span>fallback:}
</span><span><span>-</span></span><span> </span><span><span>**name<span>_prefix** (optional): ${input:name_</span></span></span><span>prefix:}

## What you will do
You will:
1) Discover all resources in an Azure **resource group** (and optionally filter providers) using the </span><span><span>**Azure MCP Server**</span></span><span> tools.
2) Generate </span><span><span>**Terraform**</span></span><span> that prefers </span><span><span>**Azure Verified Modules (AVM)**</span></span><span> where available, otherwise falls back to </span><span><span>`azurerm_*`</span></span><span>.
3) Emit </span><span><span>**`import` blocks**</span></span><span> for </span><span><span>*every*</span></span><span> discovered resource, with </span><span><span>**`to`**</span></span><span> (resource address) and </span><span><span>**`id`**</span></span><span> (full ARM ID).
4) Write files under </span><span><span>`${input:target_path:infra/${input:resource_group}}`</span></span><span> and provide a runbook to validate imports with </span><span><span>`terraform plan`</span></span><span>.

</span><span><span>## Tooling constraints</span></span><span>
</span><span><span>-</span></span><span> Use </span><span><span>**Azure MCP Server**</span></span><span> tools (Azure CLI, etc.) for discovery. Read-only only.
</span><span><span>-</span></span><span> If tools are missing, say so, print equivalent </span><span><span>`az`</span></span><span> commands, and continue based on data I provide.

</span><span><span>## Discovery steps (strict)</span></span><span>
</span><span><span>1.</span></span><span> Ensure </span><span><span>**subscription**</span></span><span> and </span><span><span>**resource group**</span></span><span> are set. If </span><span><span>`subscription_id`</span></span><span> looks like a name, resolve to GUID; then set it for subsequent calls.
</span><span><span>2.</span></span><span> List </span><span><span>**all resources**</span></span><span> in the RG. Capture at minimum: </span><span><span>`id`</span></span><span>, </span><span><span>`name`</span></span><span>, </span><span><span>`type`</span></span><span>, </span><span><span>`location`</span></span><span>, </span><span><span>`tags`</span></span><span>, plus </span><span><span>**critical attributes**</span></span><span> per type needed by Terraform/AVM.
</span><span><span>3.</span></span><span> For types missing essentials, make targeted lookups (e.g., VNets, Subnets, Storage, Web Apps/Plans, Key Vault).
</span><span><span>4.</span></span><span> Build an internal mapping: </span><span><span>**ARM type ➜ Terraform resource / AVM module**</span></span><span> (prefer AVM when practical and importable).

</span><span><span>## Generation rules (strict)</span></span><span>
Create or overwrite the following under </span><span><span>**`${input:target<span>_path:infra/${input:resource_</span></span></span><span>group}}`**:
</span><span><span>-</span></span><span> </span><span><span>`versions.tf`</span></span><span> — </span><span><span>`terraform`</span></span><span> + </span><span><span>`required_providers`</span></span><span> using </span><span><span>`${input:tf_required_version:&gt;= 1.5.0}`</span></span><span> and </span><span><span>`${input:azurerm_version:~&gt; 3.113}`</span></span><span>.
</span><span><span>-</span></span><span> </span><span><span>`providers.tf`</span></span><span> — </span><span><span>`azurerm`</span></span><span> provider, </span><span><span>`data.azurerm_resource_group`</span></span><span>, </span><span><span>`data.azurerm_subscription`</span></span><span>, and locals for </span><span><span>`location`</span></span><span> and </span><span><span>`name_prefix`</span></span><span>.
</span><span><span>-</span></span><span> </span><span><span>`main.tf`</span></span><span> — Resource definitions (AVM or </span><span><span>`azurerm_*`</span></span><span>) with </span><span><span>**minimal**</span></span><span> attributes to match existing state; favor references over literals.
</span><span><span>-</span></span><span> </span><span><span>`imports.tf`</span></span><span> — One </span><span><span>`import { to = ..., id = "..." }`</span></span><span> per discovered object. If using AVM and the child resource address is stable, import to it; otherwise add a commented import with guidance or fall back to </span><span><span>`azurerm_*`</span></span><span> for first pass.
</span><span><span>-</span></span><span> </span><span><span>`variables.tf`</span></span><span> — Inputs for </span><span><span>`resource_group`</span></span><span>, </span><span><span>`name_prefix`</span></span><span>, and </span><span><span>`location_fallback`</span></span><span> (at minimum).
</span><span><span>-</span></span><span> </span><span><span>`outputs.tf`</span></span><span> — Useful names/IDs.
</span><span><span>-</span></span><span> </span><span><span>`README.md`</span></span><span> — What was generated, how to run, any manual follow-ups, and any skipped resources with suggestions.

</span><span><span>**Resource addresses**</span></span><span>
</span><span><span>-</span></span><span> </span><span><span>`azurerm_*`</span></span><span>: </span><span><span>`resource "azurerm_&lt;type&gt;" "&lt;normalized_name&gt;"`</span></span><span>
</span><span><span>-</span></span><span> AVM: </span><span><span>`module "&lt;normalized_name&gt;" { source = "Azure/&lt;module&gt;/azurerm" ... }`</span></span><span>
</span><span><span>  -</span></span><span> Import to module child resource address </span><span><span>**only if**</span></span><span> it’s stable and documented; otherwise document a fallback.

</span><span><span>**Import blocks**</span></span><span>
<span>```hcl
import {
  to = &lt;RESOURCE ADDRESS&gt;   # e.g., azurerm_storage_account.sa_main
  id = "&lt;FULL ARM RESOURCE ID&gt;"
}
</span></span></span></code></p></div>
```

**Relationships**

-   Preserve references (e.g., subnets reference VNet, web apps reference service plan) to avoid hardcoded strings.
    

**Safety**

-   No deletes or replacements. If an attribute mismatch would cause replacement, add a comment and request the real value.
    

## Mapping hints

Prefer stable AVM modules; otherwise use `azurerm_*`.

-   Microsoft.Network/virtualNetworks → AVM VNet module or `azurerm_virtual_network` (+ `azurerm_subnet`)
    
-   Microsoft.Storage/storageAccounts → AVM storage or `azurerm_storage_account`
    
-   Microsoft.ContainerRegistry/registries → `azurerm_container_registry`
    
-   Microsoft.ContainerService/managedClusters → `azurerm_kubernetes_cluster`
    
-   Microsoft.KeyVault/vaults → `azurerm_key_vault`
    
-   Microsoft.Web/serverfarms + sites → `azurerm_service_plan`, `azurerm_linux_web_app` / `azurerm_windows_web_app`
    
-   Microsoft.DBforPostgreSQL/flexibleServers → `azurerm_postgresql_flexible_server`  
    (Perform targeted lookups for child collections like subnets, app settings, access policies, etc.)
    

## Output format (strict)

1.  Write all files to `${input:target_path:infra/${input:resource_group}}`.
    
2.  Show a **single consolidated diff/patch** of created/updated files.
    
3.  Provide a compact **runbook**:
    
    1.  `cd ${input:target_path:infra/${input:resource_group}}`
        
    2.  `terraform init`
        
    3.  `terraform plan` (verify imports, ensure zero-change)
        
    4.  `terraform apply` (only when plan is zero-change)
        

## If tools are missing

-   State clearly which tools are unavailable.
    
-   Print the exact `az` commands to run manually (copy-paste ready).
    
-   Proceed using any JSON data I paste back from `az` output.
    

___

### Quick usage examples

**Inline args (no file):**

```
<div><p>bash</p><p><code><span><span>/azure-rg-to-terraform: subscription_id=00000000-0000-0000-0000-000000000000 resource_group=rg-fitcoach-prod target_path=infra/rg-fitcoach-prod providers_filter=[</span><span><span>"Microsoft.Network"</span></span><span>,</span><span><span>"Microsoft.Storage"</span></span><span>] prefer_avm=</span><span><span>true</span></span><span> tf_required_version=</span><span><span>"&gt;= 1.6.0"</span></span><span> azurerm_version=</span><span><span>"~&gt; 3.113"</span></span><span> location_fallback=southeastasia name_prefix=fitcoach
</span></span></code></p></div>
```

**With a JSON defaults file:**

1.  In the chat box, first attach:  
    `#file:.copilot/azure-rg.inputs.json`
    
2.  Then run:  
    `/azure-rg-to-terraform: resource_group=rg-fitcoach-prod`  
    (Inline values override JSON defaults.)
    

```
<div><p>pgsql</p><p><code><span><span>
</span><span><span>If</span></span><span> you want, I can </span><span><span>also</span></span><span> </span><span><span>add</span></span><span> the tiny `.copilot/azure-rg.inputs.json` starter file </span><span><span>and</span></span><span> a one-liner `jq` command you can use </span><span><span>to</span></span><span> generate it </span><span><span>from</span></span><span> `az account </span><span><span>show</span></span><span>` + `az </span><span><span>group</span></span><span> </span><span><span>show</span></span><span>`.
::contentReference[oaicite:</span><span><span>0</span></span><span>]{</span><span><span>index</span></span><span>=</span><span><span>0</span></span><span>}
</span></span></code></p></div>
```

##### You said:

for this line If a \*\*JSON file\*\* named `.copilot/azure-rg.inputs.json` - my vscode has underlined this with "file not found" error

###### ChatGPT said:

That underline is just VS Code’s **Markdown link validation** complaining that the file doesn’t exist (yet). You have three easy fixes—pick one:

## 1) Create the file (recommended)

Make the file it points to and the warning disappears.

```
<div><p>bash</p><p><code><span><span><span># from your repo root</span></span><span>
</span><span><span>mkdir</span></span><span> -p .copilot
</span><span><span>cat</span></span><span> &gt; .copilot/azure-rg.inputs.json &lt;&lt;</span><span><span>'JSON'</span></span><span>
{
  </span><span><span>"subscription_id"</span></span><span>: </span><span><span>"00000000-0000-0000-0000-000000000000"</span></span><span>,
  </span><span><span>"resource_group"</span></span><span>: </span><span><span>"rg-fitcoach-prod"</span></span><span>,
  </span><span><span>"target_path"</span></span><span>: </span><span><span>"infra/rg-fitcoach-prod"</span></span><span>,
  </span><span><span>"providers_filter"</span></span><span>: [</span><span><span>"Microsoft.Network"</span></span><span>,</span><span><span>"Microsoft.Storage"</span></span><span>],
  </span><span><span>"prefer_avm"</span></span><span>: </span><span><span>true</span></span><span>,
  </span><span><span>"tf_required_version"</span></span><span>: </span><span><span>"&gt;= 1.6.0"</span></span><span>,
  </span><span><span>"azurerm_version"</span></span><span>: </span><span><span>"~&gt; 3.113"</span></span><span>,
  </span><span><span>"location_fallback"</span></span><span>: </span><span><span>"southeastasia"</span></span><span>,
  </span><span><span>"name_prefix"</span></span><span>: </span><span><span>"fitcoach"</span></span><span>
}
JSON
</span></span></code></p></div>
```

Then, in Copilot Chat:

```
<div><p>bash</p><p><code><span><span><span>#file:.copilot/azure-rg.inputs.json</span></span><span>
/azure-rg-to-terraform
</span></span></code></p></div>
```

## 2) Tell VS Code to ignore that path

Add a workspace setting so the validator doesn’t flag it:

**.vscode/settings.json**

```
<div><p>json</p><p><code id="code-lang-json"><span><span><span>{</span></span><span>
  </span><span><span>"markdown.validate.enabled"</span></span><span><span>:</span></span><span> </span><span><span><span>true</span></span></span><span></span><span><span>,</span></span><span>
  </span><span><span>"markdown.validate.ignoredLinks"</span></span><span><span>:</span></span><span> </span><span><span>[</span></span><span>
    </span><span><span>"**/.copilot/azure-rg.inputs.json"</span></span><span>
  </span><span><span>]</span></span><span>
</span><span><span>}</span></span><span>
</span></span></code></p></div>
```

You can also disable file-link checks entirely with:

```
<div><p>json</p><p><code id="code-lang-json"><span><span><span>"markdown.validate.fileLinks.enabled"</span></span><span><span>:</span></span><span> </span><span><span><span>false</span></span></span><span>
</span></span></code></p></div>
```

(These are the official Markdown link-validation settings in VS Code.) [Visual Studio Code](https://code.visualstudio.com/docs/languages/markdown)

## 3) Tweak the prompt wording to avoid a path-like token

If you don’t want to create the file yet, change that line in your prompt to something that won’t be parsed as a local path:

**Replace:**

> If a **JSON file** named `.copilot/azure-rg.inputs.json` is attached…

**With:**

> If a **JSON inputs file** (for example, `azure-rg.inputs.json`) is attached as chat context, parse it…

You can still attach the file via the chat **paperclip** (no `#file:` line needed).

___

### (Optional) If the underline comes from _markdownlint_ instead

You can suppress it inline:

```
<div><p>md</p><p><code id="code-lang-md"><span><span>&lt;!-- markdownlint-disable-next-line --&gt;
If a </span><span><span>**JSON file**</span></span><span> named </span><span><span>`.copilot/azure-rg.inputs.json`</span></span><span> is attached…
</span></span></code></p></div>
```

Or configure markdownlint via `.markdownlint.json`. See the extension docs for per-line disables (`markdownlint-disable-next-line`) and other options. [GitHub+1](https://github.com/DavidAnson/markdownlint?utm_source=chatgpt.com)

If you want, I can patch the exact line in your current `azure-rg-to-terraform.prompt.md` to use the safer wording in option 3.

##### You said:

When I run the prompt in GitHub copilot, it doesn't seem to discover sub resources such as subnets withing the virtual network in the Azure resources group. can you update the prompt to get copilot to discover all the resources in the RG?

###### ChatGPT said:

Got it — here’s a **drop-in replacement** for `.github/prompts/azure-rg-to-terraform.prompt.md` that adds **deep sub-resource discovery** (e.g., VNets → Subnets, NSG rules, route table routes, private endpoint DNS zone groups, LB rules, etc.) and keeps your `${input:...}` variables + JSON defaults flow.

> Save as: `.github/prompts/azure-rg-to-terraform.prompt.md`

```
<div><p>md</p><p><code id="code-lang-md"><span><span>---
mode: agent
<span>description: Deep-scan an Azure resource group via Azure MCP Server (including sub-resources) and generate Terraform + import blocks (AVM preferred, azurerm fallback).
---</span>

</span><span><span># Azure RG ➜ Terraform (code + imports)</span></span><span>

[</span><span><span>Load detailed rules &amp; mappings</span></span><span>](</span><span><span>../instructions/azure-rg-to-terraform.instructions.md</span></span><span>)

</span><span><span>## Configuration source order (highest precedence first)</span></span><span>
</span><span><span>1.</span></span><span> </span><span><span>**Inline inputs**</span></span><span> when running the prompt (e.g., </span><span><span>`/azure-rg-to-terraform: subscription_id=... resource_group=...`</span></span><span>), referenced via </span><span><span>`${input:...}`</span></span><span> below.
</span><span><span>2.</span></span><span> If a </span><span><span>**JSON inputs file**</span></span><span> is attached as chat context (e.g., </span><span><span>`#file:.copilot/azure-rg.inputs.json`</span></span><span>), </span><span><span>**parse it**</span></span><span> and use keys as defaults for any inputs not provided inline.
</span><span><span>3.</span></span><span> If anything is still missing, ask me interactively.

</span><span><span>&gt; Example JSON:</span></span><span>
</span><span><span>&gt; ```json</span></span><span>
</span><span><span>&gt; {</span></span><span>
<span>&gt;   "subscription<span>_id": "00000000-0000-0000-0000-000000000000",
&gt;   "resource_</span>group": "rg-fitcoach-prod",</span>
<span>&gt;   "target<span>_path": "infra/rg-fitcoach-prod",
&gt;   "providers_</span>filter": ["Microsoft.Network","Microsoft.Storage"],</span>
<span>&gt;   "prefer<span>_avm": true,
&gt;   "tf_</span>required<span>_version": "&gt;= 1.6.0",
&gt;   "azurerm_</span>version": "~&gt; 3.113",</span>
<span>&gt;   "location<span>_fallback": "southeastasia",
&gt;   "name_</span>prefix": "fitcoach",</span>
<span>&gt;   "include<span>_subresources": true,
&gt;   "subresource_</span>depth": "all"</span>
</span><span><span>&gt; }</span></span><span>
</span><span><span>&gt; ```</span></span><span>

</span><span><span>## Inputs (resolved via `${input:...}`; fall back to JSON when present)</span></span><span>
</span><span><span>-</span></span><span> </span><span><span>**subscription<span>_id**: ${input:subscription_</span></span></span><span>id}
- **resource<span>_group<span>**: ${input:resource_group}
- **</span>target_</span>path** (default </span><span><span>`infra/${input:resource_group}`</span></span><span>): ${input:target</span><span><span>_path:infra/${input:resource_</span></span><span>group}}
</span><span><span>-</span></span><span> </span><span><span>**providers<span>_filter** (JSON array; default `[]`): ${input:providers_</span></span></span><span>filter:[]}
- **prefer</span><span><span>_avm** (default `true`): ${input:prefer_</span></span><span>avm:true}
</span><span><span>-</span></span><span> </span><span><span>**tf<span>_required_</span></span></span><span>version** (default </span><span><span>`&gt;= 1.5.0`</span></span><span>): ${input:tf</span><span><span>_required_</span></span><span>version:&gt;= 1.5.0}
</span><span><span>-</span></span><span> </span><span><span>**azurerm<span>_version** (default `~&gt; 3.113`): ${input:azurerm_</span></span></span><span>version:~&gt; 3.113}
- **location</span><span><span>_fallback** (optional): ${input:location_</span></span><span>fallback:}
</span><span><span>-</span></span><span> </span><span><span>**name<span>_prefix** (optional): ${input:name_</span></span></span><span>prefix:}
- **include</span><span><span>_subresources** (default `true`): ${input:include_</span></span><span>subresources:true}
</span><span><span>-</span></span><span> </span><span><span>**subresource<span>_depth** (one of `basic|network|all`, default `all`): ${input:subresource_</span></span></span><span>depth:all}
- **extra</span><span><span>_subresource_</span></span><span>types** (JSON array to force-include types; default </span><span><span>`[]`</span></span><span>): ${input:extra</span><span><span>_subresource_</span></span><span>types:[]}

</span><span><span>## What you will do</span></span><span>
You will:
1) Discover all </span><span><span>**top-level**</span></span><span> resources in an Azure </span><span><span>**resource group**</span></span><span> using </span><span><span>**Azure MCP Server**</span></span><span> tools.
2) If </span><span><span>`include_subresources=true`</span></span><span>, perform </span><span><span>**targeted sub-resource sweeps**</span></span><span> so items like </span><span><span>**subnets**</span></span><span>, </span><span><span>**NSG rules**</span></span><span>, </span><span><span>**route table routes**</span></span><span>, </span><span><span>**LB rules**</span></span><span>, </span><span><span>**private endpoint DNS zone groups**</span></span><span>, etc. are captured as distinct ARM resources with full IDs.
3) Generate </span><span><span>**Terraform**</span></span><span> that prefers </span><span><span>**Azure Verified Modules (AVM)**</span></span><span> when practical, otherwise use </span><span><span>`azurerm_*`</span></span><span>.
4) Emit </span><span><span>**`import` blocks**</span></span><span> for </span><span><span>*every*</span></span><span> discovered object (top-level and sub-resources) with </span><span><span>**`to`**</span></span><span> (resource address) and </span><span><span>**`id`**</span></span><span> (full ARM ID).
5) Write files under </span><span><span>`${input:target_path:infra/${input:resource_group}}`</span></span><span> and provide a runbook to validate with </span><span><span>`terraform plan`</span></span><span>.

</span><span><span>## Tooling constraints</span></span><span>
</span><span><span>-</span></span><span> Use </span><span><span>**Azure MCP Server**</span></span><span> tools (notebooks/CLI) for discovery—</span><span><span>**read-only**</span></span><span>.
</span><span><span>-</span></span><span> If MCP tools are missing, state it, print equivalent </span><span><span>`az`</span></span><span> commands, and continue using any JSON output I paste.

</span><span><span>## Discovery steps (strict)</span></span><span>
</span><span><span>1.</span></span><span> </span><span><span>**Set subscription**</span></span><span> context from </span><span><span>`subscription_id`</span></span><span>. Resolve names → GUIDs if needed.
</span><span><span>2.</span></span><span> </span><span><span>**Top-level list**</span></span><span>: enumerate all resources in the RG and capture at least </span><span><span>`id`</span></span><span>, </span><span><span>`name`</span></span><span>, </span><span><span>`type`</span></span><span>, </span><span><span>`location`</span></span><span>, </span><span><span>`tags`</span></span><span>.
</span><span><span>3.</span></span><span> </span><span><span>**Targeted enrichment**</span></span><span> (only for resources present or when </span><span><span>`providers_filter`</span></span><span> includes the namespace):
</span><span><span>   -</span></span><span> For each parent type, run the </span><span><span>**specific sub-resource commands**</span></span><span> below and collect their full ARM IDs and required attributes.
</span><span><span>4.</span></span><span> </span><span><span>**Merge &amp; deduplicate**</span></span><span> by </span><span><span>`id`</span></span><span>. Keep the richest object per </span><span><span>`id`</span></span><span>.
</span><span><span>5.</span></span><span> Build a map </span><span><span>**ARM type ➜ Terraform resource/AVM module**</span></span><span>. Prefer AVM if importable/stable; else use </span><span><span>`azurerm_*`</span></span><span>.

<span>## Sub-resource sweep matrix (execute based on `subresource<span>_depth`)
- </span></span></span><span><span>**Core network (depth ≥ network)**</span></span><span>  
  - Virtual Networks → </span><span><span>**Subnets**</span></span><span>  
    - `az network vnet list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;` (or `show` per vnet)  
    - `az network vnet subnet list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt; --vnet-name </span><span><span id="code-lang-xml"><span>&lt;<span>vnet</span></span></span></span><span>&gt;`
  - </span><span><span>**Subnet associations**</span></span><span>: NSG, Route Table, NAT Gateway, Delegations, Service Endpoints  
    - `az network vnet subnet show -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt; --vnet-name </span><span><span id="code-lang-xml"><span>&lt;<span>vnet</span></span></span></span><span>&gt; -n </span><span><span id="code-lang-xml"><span>&lt;<span>subnet</span></span></span></span><span>&gt;`
  - Network Security Groups → </span><span><span>**Rules**</span></span><span>  
    - `az network nsg list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;`  
    - `az network nsg rule list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt; --nsg-name </span><span><span id="code-lang-xml"><span>&lt;<span>nsg</span></span></span></span><span>&gt;`
  - Route Tables → </span><span><span>**Routes**</span></span><span>  
    - `az network route-table list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;`  
    - `az network route-table route list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt; --route-table-name </span><span><span id="code-lang-xml"><span>&lt;<span>rt</span></span></span></span><span>&gt;`
  - Load Balancers → </span><span><span>**Frontends, Backends, Probes, Rules, NAT rules**</span></span><span>  
    - `az network lb list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;`  
    - `az network lb frontend-ip list ...` / `address-pool list` / `probe list` / `rule list` / `inbound-nat-rule list`
  - Application Gateways → </span><span><span>**Listeners, HTTP settings, Probes, Routing rules, Ssl certs**</span></span><span>  
    - `az network application-gateway list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;`  
    - `az network application-gateway http-listener list ...` / `http-settings list` / `probe list` / `rule list` / `ssl-cert list`
  - Public IPs, NAT Gateways, Bastion, Private Links/Endpoints  
    - `az network public-ip list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;`  
    - `az network nat gateway list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;`  
    - `az network bastion list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;`  
    - `az network private-endpoint list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;`
  - Private DNS (if present in RG) → </span><span><span>**Record sets &amp; Links**</span></span><span>  
    - `az network private-dns zone list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;`  
    - `az network private-dns link vnet list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt; -z </span><span><span id="code-lang-xml"><span>&lt;<span>zone</span></span></span></span><span>&gt;`
    - For each </span><span><span>**Private Endpoint**</span></span><span>: `az network private-endpoint dns-zone-group list --endpoint-name </span><span><span id="code-lang-xml"><span>&lt;<span>pe</span></span></span></span><span>&gt; -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;`
  - NICs → </span><span><span>**IP configurations, NSG association**</span></span><span>  
    - `az network nic list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;`  
    - `az network nic ip-config list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt; --nic-name </span><span><span id="code-lang-xml"><span>&lt;<span>nic</span></span></span></span><span>&gt;`

- </span><span><span>**Other common services (depth ≥ basic)**</span></span><span>  
  - Storage Accounts (properties essential to avoid drift)  
    - `az storage account list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;` / `show -n </span><span><span id="code-lang-xml"><span>&lt;<span>name</span></span></span></span><span>&gt;`
  - Web Apps / Plans  
    - `az appservice plan list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;`  
    - `az webapp list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;` / `webapp show -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt; -n </span><span><span id="code-lang-xml"><span>&lt;<span>app</span></span></span></span><span>&gt;`
  - Key Vault (access model, purge protection, soft delete)  
    - `az keyvault list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;` / `show -n </span><span><span id="code-lang-xml"><span>&lt;<span>name</span></span></span></span><span>&gt;`
  - AKS  
    - `az aks list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;` / `show -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt; -n </span><span><span id="code-lang-xml"><span>&lt;<span>name</span></span></span></span><span>&gt;`
  - ACR  
    - `az acr list -g </span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;` / `show -n </span><span><span id="code-lang-xml"><span>&lt;<span>name</span></span></span></span><span>&gt;`

&gt; Notes
&gt; - Some sub-resources are </span><span><span>**ARM child resources**</span></span><span> (e.g., `Microsoft.Network/virtualNetworks/subnets`) and can be imported directly. Others are </span><span><span>**module-internal collections**</span></span><span>; document imports accordingly or fall back to first-party `azurerm_<span>*`.
&gt; - </span></span><span><span>**Data-plane objects**</span></span><span> (e.g., storage containers) are typically </span><span><span>**not**</span></span><span> ARM resources; omit from import and document in README.

## Generation rules (strict)
Create/overwrite under </span><span><span>**`${input:target_path:infra/${input:resource_group}}`**</span></span><span>:
- `versions.tf` — uses `${input:tf_required_version:&gt;= 1.5.0}` and `${input:azurerm_version:~&gt; 3.113}`.
- `providers.tf` — `azurerm` provider; `data.azurerm_subscription.current`; `data.azurerm_resource_group.rg`; `locals` for `location` and `name_prefix`.
- `main.tf` — Minimal attributes to match existing state; prefer references (RG name, IDs).
- `imports.tf` — One block per discovered </span><span><span>**top-level and sub-resource**</span></span><span>:
  ```hcl
  import {
    to = </span><span><span id="code-lang-xml"><span>&lt;<span>RESOURCE</span></span></span></span><span> </span><span><span>ADDRESS</span></span><span>&gt;   # e.g., azurerm_subnet.app
    id = "</span><span><span id="code-lang-xml"><span>&lt;<span>FULL</span></span></span></span><span> </span><span><span>ARM</span></span><span> </span><span><span>ID</span></span><span>&gt;"      # e.g., /subscriptions/</span><span><span id="code-lang-xml"><span>&lt;<span>sub</span></span></span></span><span>&gt;/resourceGroups/</span><span><span id="code-lang-xml"><span>&lt;<span>rg</span></span></span></span><span>&gt;/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/app
  }
</span></span></code></p></div>
```

-   If using AVM and the child address is stable, import to that internal address; otherwise add a **commented** import with guidance or prefer `azurerm_*` for first pass.
    
-   `variables.tf`, `outputs.tf`, `README.md` (what was generated, how to run, skipped/unsupported mappings, and any cross-RG references discovered).
    

**Relationships**

-   Preserve associations (e.g., `subnet` ↔ `nsg`/`route_table`/`nat_gateway`, `webapp` ↔ `service_plan`) with references instead of hard-coded strings.
    

**Safety**

-   No destructive actions. If a default would cause replacement, emit a TODO and the CLI to fetch the real value.
    

## Mapping hints

Prefer stable AVM modules; else `azurerm_*`.

-   VNets/Subnets → `azurerm_virtual_network`, `azurerm_subnet` (or AVM VNet)
    
-   NSGs/Rules → `azurerm_network_security_group`, `azurerm_network_security_rule`
    
-   Route tables/Routes → `azurerm_route_table`, `azurerm_route`
    
-   LBs/Rules/Probes → `azurerm_lb`, `azurerm_lb_rule`, `azurerm_lb_probe`, etc.
    
-   Private DNS/Links → `azurerm_private_dns_zone`, `azurerm_private_dns_zone_virtual_network_link`, records as needed
    
-   Private Endpoints/Zone groups → `azurerm_private_endpoint`, `azurerm_private_dns_zone_group`
    
-   Storage, ACR, AKS, KV, App Service → respective `azurerm_*` (or AVM where viable)
    

## Output format (strict)

1.  Write all files to `${input:target_path:infra/${input:resource_group}}`.
    
2.  Show a **single consolidated diff/patch** of created/updated files.
    
3.  Provide a compact **runbook**:
    
    1.  `cd ${input:target_path:infra/${input:resource_group}}`
        
    2.  `terraform init`
        
    3.  `terraform plan` (verify imports; ensure zero-change)
        
    4.  `terraform apply` (only when plan is zero-change)
        

## Performance & scope controls

-   If discovery is slow or noisy, **respect `providers_filter`** to limit namespaces and **adjust `subresource_depth`**:
    
    -   `basic`: no network-heavy children; minimal enrich.
        
    -   `network`: include core network sub-resources.
        
    -   `all`: include everything listed above.
        
-   Always print a summary of counts per type at the end of discovery.
    

## If tools are missing

-   State which MCP/CLI tools are unavailable.
    
-   Print exact `az` CLI commands (copy-paste ready) I can run manually.
    
-   Proceed using any JSON output I paste back.
    

___

### Quick usage examples

**Deep network scan (default):**

```
<div><p>pgsql</p><p><code><span><span>/azure-rg-</span><span><span>to</span></span><span>-terraform: subscription_id=</span><span><span>00000000</span></span><span><span>-0000</span></span><span><span>-0000</span></span><span><span>-0000</span></span><span><span>-000000000000</span></span><span> resource_group=rg-fitcoach-prod subresource_depth=</span><span><span>all</span></span><span> include_subresources=</span><span><span>true</span></span><span>
</span></span></code></p></div>
```

**Limit to Microsoft.Network + Storage, still include subnets & NSG rules:**

```
<div><p>bash</p><p><code><span><span>/azure-rg-to-terraform: subscription_id=00000000-0000-0000-0000-000000000000 resource_group=rg-fitcoach-prod providers_filter=[</span><span><span>"Microsoft.Network"</span></span><span>,</span><span><span>"Microsoft.Storage"</span></span><span>] subresource_depth=network
</span></span></code></p></div>
```

**Force extra subresource types (by ARM type name):**

```
<div><p>bash</p><p><code><span><span>/azure-rg-to-terraform: resource_group=rg-fitcoach-prod extra_subresource_types=[</span><span><span>"Microsoft.Network/applicationGateways/httpListeners"</span></span><span>,</span><span><span>"Microsoft.Network/loadBalancers/rules"</span></span><span>]
</span></span></code></p></div>
```

```
<div><p>pgsql</p><p><code><span><span>
</span><span><span>If</span></span><span> you </span><span><span>also</span></span><span> want me </span><span><span>to</span></span><span> patch the **instructions.md** </span><span><span>to</span></span><span> </span><span><span>include</span></span><span> the exact MCP/CLI calls </span><span><span>for</span></span><span> </span><span><span>each</span></span><span> sweep (so Copilot has </span><span><span>no</span></span><span> wiggle room), say the word </span><span><span>and</span></span><span> I’ll </span><span><span>drop</span></span><span> that </span><span><span>in</span></span><span> too.
::contentReference[oaicite:</span><span><span>0</span></span><span>]{</span><span><span>index</span></span><span>=</span><span><span>0</span></span><span>}
</span></span></code></p></div>
```

##### You said:

right now this prompt runs "az network <resource> list" on all network resources. I want GitHub copilot to use the Azure MCP server to scan a resource group and detect all resource in the RG, no matter the type and then create the Terraform code and the Import blocks for all resources and sub resources?

###### ChatGPT said:

Awesome—here’s a **drop-in replacement** for `.github/prompts/azure-rg-to-terraform.prompt.md` that makes Copilot (Agent mode) use the **Azure MCP Server** to enumerate **all** resources in the RG (any provider/namespace), then performs a **provider-driven sub-resource sweep** so children (e.g., subnets, rules, routes, zone groups, etc.) are also discovered. It keeps your `${input:...}` variables + optional JSON-defaults flow, and adds an **AzAPI fallback** for types not covered by AVM/azurerm so you still get Terraform + `import` blocks for everything.

> Save as: `.github/prompts/azure-rg-to-terraform.prompt.md`

```
<div><p>md</p><p><code id="code-lang-md"><span><span>---
mode: agent
<span>description: Deep-scan ALL Azure resources in a resource group via Azure MCP Server (generic + provider-driven child discovery) and generate Terraform + import blocks (AVM preferred, azurerm fallback, AzAPI for unknowns).
---</span>

</span><span><span># Azure RG ➜ Terraform (ALL resources + sub-resources)</span></span><span>

[</span><span><span>Load detailed rules &amp; mappings</span></span><span>](</span><span><span>../instructions/azure-rg-to-terraform.instructions.md</span></span><span>)

</span><span><span>## Configuration source order (highest precedence first)</span></span><span>
</span><span><span>1.</span></span><span> </span><span><span>**Inline inputs**</span></span><span> when running the prompt (e.g., </span><span><span>`/azure-rg-to-terraform: subscription_id=... resource_group=...`</span></span><span>), referenced via </span><span><span>`${input:...}`</span></span><span> below.
</span><span><span>2.</span></span><span> If a </span><span><span>**JSON inputs file**</span></span><span> is attached as chat context (e.g., </span><span><span>`#file:.copilot/azure-rg.inputs.json`</span></span><span>), </span><span><span>**parse it**</span></span><span> and use keys as defaults for any inputs not provided inline.
</span><span><span>3.</span></span><span> If anything is still missing, ask me interactively.

</span><span><span>&gt; Example JSON:</span></span><span>
</span><span><span>&gt; ```json</span></span><span>
</span><span><span>&gt; {</span></span><span>
<span>&gt;   "subscription<span>_id": "00000000-0000-0000-0000-000000000000",
&gt;   "resource_</span>group": "rg-fitcoach-prod",</span>
<span>&gt;   "target<span>_path": "infra/rg-fitcoach-prod",
&gt;   "providers_</span>filter": [],</span>
<span>&gt;   "prefer<span>_avm": true,
&gt;   "tf_</span>required<span>_version": "&gt;= 1.6.0",
&gt;   "azurerm_</span>version": "~&gt; 3.113",</span>
<span>&gt;   "azapi<span>_version": "~&gt; 1.13",
&gt;   "location_</span>fallback": "southeastasia",</span>
<span>&gt;   "name<span>_prefix": "fitcoach",
&gt;   "include_</span>subresources": true,</span>
<span>&gt;   "subresource<span>_depth": "all",
&gt;   "api_</span>version<span>_strategy": "latest"  // latest | stable
&gt; }
&gt; ```

## Inputs (resolved via `${input:...}`; fall back to JSON when present)
- </span></span></span><span><span>**subscription_id**</span></span><span>: ${input:subscription_id}
</span><span><span>-</span></span><span> </span><span><span>**resource<span>_group**: ${input:resource_</span></span></span><span>group}
- **target</span><span><span>_path** (default `infra/${input:resource_</span></span><span>group}`): ${input:target</span><span><span>_path:infra/${input:resource_</span></span><span>group}}
</span><span><span>-</span></span><span> </span><span><span>**providers<span>_filter** (JSON array; default `[]` for ALL): ${input:providers_</span></span></span><span>filter:[]}
- **prefer</span><span><span>_avm** (default `true`): ${input:prefer_</span></span><span>avm:true}
</span><span><span>-</span></span><span> </span><span><span>**tf<span>_required_</span></span></span><span>version** (default </span><span><span>`&gt;= 1.5.0`</span></span><span>): ${input:tf</span><span><span>_required_</span></span><span>version:&gt;= 1.5.0}
</span><span><span>-</span></span><span> </span><span><span>**azurerm<span>_version** (default `~&gt; 3.113`): ${input:azurerm_</span></span></span><span>version:~&gt; 3.113}
- **azapi</span><span><span>_version** (default `~&gt; 1.13`): ${input:azapi_</span></span><span>version:~&gt; 1.13}
</span><span><span>-</span></span><span> </span><span><span>**location<span>_fallback** (optional): ${input:location_</span></span></span><span>fallback:}
- **name</span><span><span>_prefix** (optional): ${input:name_</span></span><span>prefix:}
</span><span><span>-</span></span><span> </span><span><span>**include<span>_subresources** (default `true`): ${input:include_</span></span></span><span>subresources:true}
- **subresource</span><span><span>_depth** (`basic|network|all`, default `all`): ${input:subresource_</span></span><span>depth:all}
</span><span><span>-</span></span><span> </span><span><span>**api<span>_version_</span></span></span><span>strategy** (</span><span><span>`latest|stable`</span></span><span>, default </span><span><span>`latest`</span></span><span>): ${input:api</span><span><span>_version_</span></span><span>strategy:latest}

</span><span><span>## What you will do</span></span><span>
You will:
1) Use </span><span><span>**Azure MCP Server**</span></span><span> tools to enumerate </span><span><span>**all**</span></span><span> resources in the target resource group (any provider/namespace).
2) Perform a </span><span><span>**provider-driven child sweep**</span></span><span> so </span><span><span>**sub-resources**</span></span><span> are discovered (e.g., VNets→Subnets, NSGs→Rules, RouteTables→Routes, LBs→Rules/Probes, AppGW children, Private Endpoint DNS zone groups, etc.).
3) Generate </span><span><span>**Terraform**</span></span><span>:
</span><span><span>   -</span></span><span> Prefer </span><span><span>**AVM**</span></span><span> modules where import addresses are stable.
</span><span><span>   -</span></span><span> Otherwise use <span>**`azurerm<span>_*`**.
   - If unsupported/unknown, use **`azapi_</span>resource`**</span> (AzAPI) so every resource can be represented and imported.
4) Emit </span><span><span>**`import` blocks**</span></span><span> for </span><span><span>*every*</span></span><span> discovered object with </span><span><span>**`to`**</span></span><span> (Terraform address) and </span><span><span>**`id`**</span></span><span> (full ARM ID).
5) Write files under </span><span><span>`${input:target_path:infra/${input:resource_group}}`</span></span><span> and provide a runbook to validate with </span><span><span>`terraform plan`</span></span><span>.

</span><span><span>## Tooling inventory (use these in this order)</span></span><span>
</span><span><span>-</span></span><span> </span><span><span>**Azure CLI tool**</span></span><span> via MCP (read-only):
</span><span><span>  -</span></span><span> </span><span><span>`az account list`</span></span><span>, </span><span><span>`az account set --subscription &lt;id&gt;`</span></span><span>
</span><span><span>  -</span></span><span> </span><span><span>`az resource list -g &lt;rg&gt; --output json`</span></span><span>  ← generic flatten of top-level + many children
</span><span><span>-</span></span><span> </span><span><span>**ARM REST/HTTP tool**</span></span><span> via MCP (read-only) for comprehensive coverage:
</span><span><span>  -</span></span><span> List </span><span><span>**providers**</span></span><span>: </span><span><span>`GET /subscriptions/{sub}/providers?api-version=2021-04-01`</span></span><span>
</span><span><span>  -</span></span><span> For each provider </span><span><span>**resourceType**</span></span><span> that is </span><span><span>**resourceGroup-scoped**</span></span><span>:
</span><span><span>    -</span></span><span> If the type has </span><span><span>**no parent**</span></span><span> (no </span><span><span>`/`</span></span><span> in the name), list with:  
<span>      `GET /subscriptions/{sub}/resourceGroups/{rg}/providers/{ns}/{type}?api-version=&lt;best&gt;`
    - If the type has **a parent** (contains `/`), **iterate each discovered parent instance** and list children with:  
      `GET /subscriptions/{sub}/resourceGroups/{rg}/providers/{ns}/{parentType}/{parentName}/{childType}?api-version=&lt;best&gt;`
  - Choose `&lt;best&gt;` api-version per type using **`${input:api_version_strategy}`**:
    - `latest`: pick the **max** version returned by the provider
    - `stable`: pick the newest **YYYY-MM-DD** (exclude `preview`)
- **Fallback when MCP tools missing**: print equivalent `az` CLI/`az rest` commands for me to run and continue with pasted JSON.
</span>
</span><span><span>## Discovery algorithm (strict)</span></span><span>
</span><span><span>1.</span></span><span> </span><span><span>**Resolve subscription**</span></span><span>:
</span><span><span>   -</span></span><span> If </span><span><span>`${input:subscription_id}`</span></span><span> is a name, resolve to GUID and </span><span><span>`az account set`</span></span><span>.
</span><span><span>2.</span></span><span> </span><span><span>**Primary generic sweep**</span></span><span>:
</span><span><span>   -</span></span><span> Run </span><span><span>`az resource list -g &lt;rg&gt;`</span></span><span>; capture </span><span><span>`id,name,type,location,tags`</span></span><span> and any embedded </span><span><span>`properties`</span></span><span>.
</span><span><span>3.</span></span><span> </span><span><span>**Provider-driven child sweep**</span></span><span> (ensures sub-resources show up):
</span><span><span>   -</span></span><span> </span><span><span>`GET /subscriptions/{sub}/providers?...`</span></span><span>
</span><span><span>   -</span></span><span> Build a catalog of </span><span><span>`{namespace, resourceType, apiVersion, isChild, parentChain, scopeIncludesRG}`</span></span><span>.
</span><span><span>   -</span></span><span> Respect </span><span><span>`${input:providers_filter}`</span></span><span> if non-empty.
</span><span><span>   -</span></span><span> For </span><span><span>**isChild=false**</span></span><span> types: list directly at RG scope.
</span><span><span>   -</span></span><span> For </span><span><span>**isChild=true**</span></span><span> types: for each </span><span><span>**parent instance**</span></span><span> previously discovered in this RG, list children by expanding the correct path. Repeat for </span><span><span>**multi-level chains**</span></span><span> (e.g., </span><span><span>`.../virtualNetworks/{vnet}/subnets/{subnet}/serviceAssociationLinks`</span></span><span>).
</span><span><span>   -</span></span><span> Throttle and paginate as needed; </span><span><span>**deduplicate by `id`**</span></span><span>, keeping the richest object.
</span><span><span>4.</span></span><span> </span><span><span>**Normalization**</span></span><span>:
</span><span><span>   -</span></span><span> For each object, compute: </span><span><span>`arm_id`</span></span><span>, </span><span><span>`name`</span></span><span>, </span><span><span>`type`</span></span><span> (namespace + type), </span><span><span>`parent_id`</span></span><span> (if any), </span><span><span>`location`</span></span><span>, </span><span><span>`tags`</span></span><span>, and </span><span><span>**minimal required attributes**</span></span><span> to avoid Terraform drift (SKUs, address spaces, plans, etc.).
</span><span><span>   -</span></span><span> Track </span><span><span>**cross-RG references**</span></span><span> (note in README if parents live outside the RG).

</span><span><span>## Terraform generation rules (strict)</span></span><span>
Create/overwrite under </span><span><span>**`${input:target<span>_path:infra/${input:resource_</span></span></span><span>group}}`**:
</span><span><span>-</span></span><span> </span><span><span>`versions.tf`</span></span><span> — uses </span><span><span>`${input:tf_required_version}`</span></span><span>; providers </span><span><span>`azurerm = ${input:azurerm_version}`</span></span><span> and </span><span><span>`azapi = ${input:azapi_version}`</span></span><span>.
</span><span><span>-</span></span><span> </span><span><span>`providers.tf`</span></span><span> — </span><span><span>`provider "azurerm" { features {} }`</span></span><span>, </span><span><span>`provider "azapi" {}`</span></span><span>; </span><span><span>`data.azurerm_subscription.current`</span></span><span>; </span><span><span>`data.azurerm_resource_group.rg`</span></span><span>; </span><span><span>`locals`</span></span><span> for </span><span><span>`location`</span></span><span> (fallback to </span><span><span>`${input:location_fallback}`</span></span><span>) and </span><span><span>`name_prefix`</span></span><span>.
</span><span><span>-</span></span><span> </span><span><span>`variables.tf`</span></span><span> — at least </span><span><span>`resource_group`</span></span><span>, </span><span><span>`name_prefix`</span></span><span>, </span><span><span>`location_fallback`</span></span><span>.
</span><span><span>-</span></span><span> </span><span><span>`main.tf`</span></span><span> — for each discovered </span><span><span>**type**</span></span><span>:
</span><span><span>  -</span></span><span> </span><span><span>**Prefer AVM**</span></span><span> if importable/stable; else <span>**`azurerm<span>_*`**.
  - If **unknown/unsupported**, generate **`azapi_</span>resource`**</span>:
<span>    ```hcl
    resource "azapi_resource" "&lt;normalized_name&gt;" {
      type      = "&lt;Namespace/Type@&lt;apiVersion&gt;&gt;"
      name      = "&lt;name&gt;"
      parent_id = "&lt;parent ARM id or data.azurerm_resource_group.rg.id&gt;"
      location  = local.location
      body      = {}
      lifecycle { ignore_changes = [body] }
    }
    ```
  - Use references instead of string literals (e.g., RG name, IDs).
- `imports.tf` — one block per discovered object:
  ```hcl
  import {
    to = &lt;RESOURCE ADDRESS&gt;   # e.g., azurerm_subnet.app OR azapi_resource.pe1
    id = "&lt;FULL ARM ID&gt;"
  }
</span></span></span></code></p></div>
```

-   If using AVM and the **child resource address** is not stable, either:
    
    -   Import to the underlying `azurerm_*` equivalent **or**
        
    -   Comment the import with guidance and generate an `azurerm_*` first pass.
        
-   `outputs.tf` — helpful IDs/names.
    
-   `README.md` — what was generated, how to run, any skipped or cross-RG references, and how AzAPI is used for unknowns.
    

**Relationships**

-   Preserve associations (e.g., subnet ↔ nsg/routeTable/natGateway; webapp ↔ service plan; private endpoint ↔ zone groups) using references.
    

**Safety**

-   No destructive actions. If a default might cause replacement, add a TODO and emit the precise CLI/REST to fetch the real value.
    

## Mapping hints (not exhaustive; prefer AVM when importable)

-   VNets/Subnets → AVM VNet or `azurerm_virtual_network` + `azurerm_subnet`
    
-   NSGs/Rules → `azurerm_network_security_group` + `azurerm_network_security_rule`
    
-   Route tables/Routes → `azurerm_route_table` + `azurerm_route`
    
-   LBs/Rules/Probes/NAT → `azurerm_lb` + children
    
-   App Gateway/children → `azurerm_application_gateway`
    
-   Private DNS/links/records → `azurerm_private_dns_*`
    
-   Private Endpoints/Zone groups → `azurerm_private_endpoint` + `azurerm_private_dns_zone_group`
    
-   Storage/ACR/AKS/KV/App Service → respective `azurerm_*`
    
-   **Anything unknown** → `azapi_resource`
    

## Output format (strict)

1.  Write all files to `${input:target_path:infra/${input:resource_group}}`.
    
2.  Show a **single consolidated diff/patch** of created/updated files.
    
3.  Provide a compact **runbook**:
    
    1.  `cd ${input:target_path:infra/${input:resource_group}}`
        
    2.  `terraform init`
        
    3.  `terraform plan` (verify imports; ensure zero-change)
        
    4.  `terraform apply` (only when plan is zero-change)
        

## Performance & scope controls

-   Respect `${input:providers_filter}` to limit namespaces (empty = ALL).
    
-   Use `${input:subresource_depth}` to gate expensive sweeps:
    
    -   `basic`: no deep children; just top-level + a few essentials
        
    -   `network`: include core network children
        
    -   `all`: include full matrix
        
-   Print a summary of counts per **ARM type** at end of discovery.
    

## If tools are missing

-   State which MCP/CLI/REST tools are unavailable.
    
-   Print exact `az`/`az rest` commands (copy-paste ready) I can run manually.
    
-   Proceed using any JSON output I paste back.
    

___

### Quick usage examples

**Scan everything (default strategy):**

```
<div><p>pgsql</p><p><code><span><span>/azure-rg-</span><span><span>to</span></span><span>-terraform: subscription_id=</span><span><span>00000000</span></span><span><span>-0000</span></span><span><span>-0000</span></span><span><span>-0000</span></span><span><span>-000000000000</span></span><span> resource_group=rg-fitcoach-prod subresource_depth=</span><span><span>all</span></span><span> include_subresources=</span><span><span>true</span></span><span>
</span></span></code></p></div>
```

**Scan only selected providers (for speed), still with child sweep:**

```
<div><p>pgsql</p><p><code><span><span>/azure-rg-</span><span><span>to</span></span><span>-terraform: resource_group=rg-fitcoach-prod providers_filter=["Microsoft.Network","Microsoft.Storage","Microsoft.Web"] subresource_depth=</span><span><span>all</span></span><span>
</span></span></code></p></div>
```

**Prefer stable API versions (exclude preview):**

```
<div><p>pgsql</p><p><code><span><span>/azure-rg-</span><span><span>to</span></span><span>-terraform: resource_group=rg-fitcoach-prod api_version_strategy=</span><span><span>stable</span></span><span>
</span></span></code></p></div>
```

```
<div><p>pgsql</p><p><code><span><span>
</span><span><span>If</span></span><span> you want, I can patch your `instructions.md` </span><span><span>to</span></span><span> </span><span><span>include</span></span><span> the exact **ARM REST paths** Copilot should </span><span><span>call</span></span><span> </span><span><span>for</span></span><span> parent/child chains, plus a minimal AzAPI </span><span><span>template</span></span><span> you can reuse per </span><span><span>unknown</span></span><span> </span><span><span>type</span></span><span>.
::contentReference[oaicite:</span><span><span>0</span></span><span>]{</span><span><span>index</span></span><span>=</span><span><span>0</span></span><span>}
</span></span></code></p></div>
```

##### You said:

I am running VSCOde on Window so the paths in the .MD file should be windows paths, otherwise GitHub Copilot does not find them. please update

###### ChatGPT said:

Gotcha. Here’s a **Windows-optimized** drop-in for `.github\prompts\azure-rg-to-terraform.prompt.md` using **backslashes** for paths so Copilot (VS Code on Windows) resolves links and examples correctly.

> Save as: **`.github\prompts\azure-rg-to-terraform.prompt.md`**

```
<div><p>md</p><p><code id="code-lang-md"><span><span>---
mode: agent
<span>description: Deep-scan ALL Azure resources in a resource group via Azure MCP Server (generic + provider-driven child discovery) and generate Terraform + import blocks (AVM preferred, azurerm fallback, AzAPI for unknowns).
---</span>

</span><span><span># Azure RG ➜ Terraform (ALL resources + sub-resources)</span></span><span>

[</span><span><span>Load detailed rules &amp; mappings</span></span><span>](</span><span><span>..\\instructions\\azure-rg-to-terraform.instructions.md</span></span><span>)

</span><span><span>## Configuration source order (highest precedence first)</span></span><span>
</span><span><span>1.</span></span><span> </span><span><span>**Inline inputs**</span></span><span> when running the prompt (e.g., </span><span><span>`/azure-rg-to-terraform: subscription_id=... resource_group=...`</span></span><span>), referenced via </span><span><span>`${input:...}`</span></span><span> below.
</span><span><span>2.</span></span><span> If a </span><span><span>**JSON inputs file**</span></span><span> is attached as chat context (e.g., </span><span><span>`#file:.copilot\\azure-rg.inputs.json`</span></span><span>), </span><span><span>**parse it**</span></span><span> and use keys as defaults for any inputs not provided inline.
</span><span><span>3.</span></span><span> If anything is still missing, ask me interactively.

</span><span><span>&gt; Example JSON:</span></span><span>
</span><span><span>&gt; ```json</span></span><span>
</span><span><span>&gt; {</span></span><span>
<span>&gt;   "subscription<span>_id": "00000000-0000-0000-0000-000000000000",
&gt;   "resource_</span>group": "rg-fitcoach-prod",</span>
<span>&gt;   "target<span>_path": "infra\\rg-fitcoach-prod",
&gt;   "providers_</span>filter": [],</span>
<span>&gt;   "prefer<span>_avm": true,
&gt;   "tf_</span>required<span>_version": "&gt;= 1.6.0",
&gt;   "azurerm_</span>version": "~&gt; 3.113",</span>
<span>&gt;   "azapi<span>_version": "~&gt; 1.13",
&gt;   "location_</span>fallback": "southeastasia",</span>
<span>&gt;   "name<span>_prefix": "fitcoach",
&gt;   "include_</span>subresources": true,</span>
<span>&gt;   "subresource<span>_depth": "all",
&gt;   "api_</span>version<span>_strategy": "latest"
&gt; }
&gt; ```

## Inputs (resolved via `${input:...}`; fall back to JSON when present)
- </span></span></span><span><span>**subscription_id**</span></span><span>: ${input:subscription_id}
</span><span><span>-</span></span><span> </span><span><span>**resource<span>_group**: ${input:resource_</span></span></span><span>group}
- **target</span><span><span>_path** (default `infra\\${input:resource_</span></span><span>group}`): ${input:target</span><span><span>_path:infra\\${input:resource_</span></span><span>group}}
</span><span><span>-</span></span><span> </span><span><span>**providers<span>_filter** (JSON array; default `[]` for ALL): ${input:providers_</span></span></span><span>filter:[]}
- **prefer</span><span><span>_avm** (default `true`): ${input:prefer_</span></span><span>avm:true}
</span><span><span>-</span></span><span> </span><span><span>**tf<span>_required_</span></span></span><span>version** (default </span><span><span>`&gt;= 1.5.0`</span></span><span>): ${input:tf</span><span><span>_required_</span></span><span>version:&gt;= 1.5.0}
</span><span><span>-</span></span><span> </span><span><span>**azurerm<span>_version** (default `~&gt; 3.113`): ${input:azurerm_</span></span></span><span>version:~&gt; 3.113}
- **azapi</span><span><span>_version** (default `~&gt; 1.13`): ${input:azapi_</span></span><span>version:~&gt; 1.13}
</span><span><span>-</span></span><span> </span><span><span>**location<span>_fallback** (optional): ${input:location_</span></span></span><span>fallback:}
- **name</span><span><span>_prefix** (optional): ${input:name_</span></span><span>prefix:}
</span><span><span>-</span></span><span> </span><span><span>**include<span>_subresources** (default `true`): ${input:include_</span></span></span><span>subresources:true}
- **subresource</span><span><span>_depth** (`basic|network|all`, default `all`): ${input:subresource_</span></span><span>depth:all}
</span><span><span>-</span></span><span> </span><span><span>**api<span>_version_</span></span></span><span>strategy** (</span><span><span>`latest|stable`</span></span><span>, default </span><span><span>`latest`</span></span><span>): ${input:api</span><span><span>_version_</span></span><span>strategy:latest}

</span><span><span>## What you will do</span></span><span>
You will:
1) Use </span><span><span>**Azure MCP Server**</span></span><span> tools to enumerate </span><span><span>**all**</span></span><span> resources in the target resource group (any provider/namespace).
2) Perform a </span><span><span>**provider-driven child sweep**</span></span><span> so </span><span><span>**sub-resources**</span></span><span> are discovered (e.g., VNets→Subnets, NSGs→Rules, RouteTables→Routes, LBs→Rules/Probes, AppGW children, Private Endpoint DNS zone groups, etc.).
3) Generate </span><span><span>**Terraform**</span></span><span>:
</span><span><span>   -</span></span><span> Prefer </span><span><span>**AVM**</span></span><span> modules where import addresses are stable.
</span><span><span>   -</span></span><span> Otherwise use <span>**`azurerm<span>_*`**.
   - If unsupported/unknown, use **`azapi_</span>resource`**</span> (AzAPI) so every resource can be represented and imported.
4) Emit </span><span><span>**`import` blocks**</span></span><span> for </span><span><span>*every*</span></span><span> discovered object with </span><span><span>**`to`**</span></span><span> (Terraform address) and </span><span><span>**`id`**</span></span><span> (full ARM ID).
5) Write files under </span><span><span>`${input:target_path:infra\\${input:resource_group}}`</span></span><span> and provide a runbook to validate with </span><span><span>`terraform plan`</span></span><span>.

</span><span><span>## Tooling inventory (use these in this order)</span></span><span>
</span><span><span>-</span></span><span> </span><span><span>**Azure CLI tool**</span></span><span> via MCP (read-only):
</span><span><span>  -</span></span><span> </span><span><span>`az account list`</span></span><span>, </span><span><span>`az account set --subscription &lt;id&gt;`</span></span><span>
</span><span><span>  -</span></span><span> </span><span><span>`az resource list -g &lt;rg&gt; --output json`</span></span><span>  ← generic flatten of top-level + many children
</span><span><span>-</span></span><span> </span><span><span>**ARM REST/HTTP tool**</span></span><span> via MCP (read-only) for comprehensive coverage:
</span><span><span>  -</span></span><span> List </span><span><span>**providers**</span></span><span>: </span><span><span>`GET /subscriptions/{sub}/providers?api-version=2021-04-01`</span></span><span>
</span><span><span>  -</span></span><span> For each provider </span><span><span>**resourceType**</span></span><span> that is </span><span><span>**resourceGroup-scoped**</span></span><span>:
</span><span><span>    -</span></span><span> If the type has </span><span><span>**no parent**</span></span><span> (no </span><span><span>`/`</span></span><span> in the name), list with:  
<span>      `GET /subscriptions/{sub}/resourceGroups/{rg}/providers/{ns}/{type}?api-version=&lt;best&gt;`
    - If the type has **a parent** (contains `/`), **iterate each discovered parent instance** and list children with:  
      `GET /subscriptions/{sub}/resourceGroups/{rg}/providers/{ns}/{parentType}/{parentName}/{childType}?api-version=&lt;best&gt;`
  - Choose `&lt;best&gt;` api-version per type using **`${input:api_version_strategy}`**:
    - `latest`: pick the **max** version returned by the provider
    - `stable`: pick the newest **YYYY-MM-DD** (exclude `preview`)
- **Fallback when MCP tools missing**: print equivalent `az` CLI/`az rest` commands for me to run and continue with pasted JSON.
</span>
</span><span><span>## Discovery algorithm (strict)</span></span><span>
</span><span><span>1.</span></span><span> </span><span><span>**Resolve subscription**</span></span><span>:
</span><span><span>   -</span></span><span> If </span><span><span>`${input:subscription_id}`</span></span><span> is a name, resolve to GUID and </span><span><span>`az account set`</span></span><span>.
</span><span><span>2.</span></span><span> </span><span><span>**Primary generic sweep**</span></span><span>:
</span><span><span>   -</span></span><span> Run </span><span><span>`az resource list -g &lt;rg&gt;`</span></span><span>; capture </span><span><span>`id,name,type,location,tags`</span></span><span> and any embedded </span><span><span>`properties`</span></span><span>.
</span><span><span>3.</span></span><span> </span><span><span>**Provider-driven child sweep**</span></span><span> (ensures sub-resources show up):
</span><span><span>   -</span></span><span> </span><span><span>`GET /subscriptions/{sub}/providers?...`</span></span><span>
</span><span><span>   -</span></span><span> Build a catalog of </span><span><span>`{namespace, resourceType, apiVersion, isChild, parentChain, scopeIncludesRG}`</span></span><span>.
</span><span><span>   -</span></span><span> Respect </span><span><span>`${input:providers_filter}`</span></span><span> if non-empty.
</span><span><span>   -</span></span><span> For </span><span><span>**isChild=false**</span></span><span> types: list directly at RG scope.
</span><span><span>   -</span></span><span> For </span><span><span>**isChild=true**</span></span><span> types: for each </span><span><span>**parent instance**</span></span><span> previously discovered in this RG, list children by expanding the correct path. Repeat for </span><span><span>**multi-level chains**</span></span><span>.
</span><span><span>   -</span></span><span> Throttle and paginate as needed; </span><span><span>**deduplicate by `id`**</span></span><span>, keeping the richest object.
</span><span><span>4.</span></span><span> </span><span><span>**Normalization**</span></span><span>:
</span><span><span>   -</span></span><span> For each object, compute: </span><span><span>`arm_id`</span></span><span>, </span><span><span>`name`</span></span><span>, </span><span><span>`type`</span></span><span> (namespace + type), </span><span><span>`parent_id`</span></span><span> (if any), </span><span><span>`location`</span></span><span>, </span><span><span>`tags`</span></span><span>, and </span><span><span>**minimal required attributes**</span></span><span> to avoid Terraform drift (SKUs, address spaces, plans, etc.).
</span><span><span>   -</span></span><span> Track </span><span><span>**cross-RG references**</span></span><span> (note in README if parents live outside the RG).

</span><span><span>## Terraform generation rules (strict)</span></span><span>
Create/overwrite under </span><span><span>**`${input:target<span>_path:infra\\${input:resource_</span></span></span><span>group}}`**:
</span><span><span>-</span></span><span> </span><span><span>`versions.tf`</span></span><span> — uses </span><span><span>`${input:tf_required_version}`</span></span><span>; providers </span><span><span>`azurerm = ${input:azurerm_version}`</span></span><span> and </span><span><span>`azapi = ${input:azapi_version}`</span></span><span>.
</span><span><span>-</span></span><span> </span><span><span>`providers.tf`</span></span><span> — </span><span><span>`provider "azurerm" { features {} }`</span></span><span>, </span><span><span>`provider "azapi" {}`</span></span><span>; </span><span><span>`data.azurerm_subscription.current`</span></span><span>; </span><span><span>`data.azurerm_resource_group.rg`</span></span><span>; </span><span><span>`locals`</span></span><span> for </span><span><span>`location`</span></span><span> (fallback to </span><span><span>`${input:location_fallback}`</span></span><span>) and </span><span><span>`name_prefix`</span></span><span>.
</span><span><span>-</span></span><span> </span><span><span>`variables.tf`</span></span><span> — at least </span><span><span>`resource_group`</span></span><span>, </span><span><span>`name_prefix`</span></span><span>, </span><span><span>`location_fallback`</span></span><span>.
</span><span><span>-</span></span><span> </span><span><span>`main.tf`</span></span><span> — for each discovered </span><span><span>**type**</span></span><span>:
</span><span><span>  -</span></span><span> </span><span><span>**Prefer AVM**</span></span><span> if importable/stable; else <span>**`azurerm<span>_*`**.
  - If **unknown/unsupported**, generate **`azapi_</span>resource`**</span>:
<span>    ```hcl
    resource "azapi_resource" "&lt;normalized_name&gt;" {
      type      = "&lt;Namespace/Type@&lt;apiVersion&gt;&gt;"
      name      = "&lt;name&gt;"
      parent_id = "&lt;parent ARM id or data.azurerm_resource_group.rg.id&gt;"
      location  = local.location
      body      = {}
      lifecycle { ignore_changes = [body] }
    }
    ```
  - Use references instead of string literals (e.g., RG name, IDs).
- `imports.tf` — one block per discovered object:
  ```hcl
  import {
    to = &lt;RESOURCE ADDRESS&gt;   # e.g., azurerm_subnet.app OR azapi_resource.pe1
    id = "&lt;FULL ARM ID&gt;"
  }
</span></span></span></code></p></div>
```

-   If using AVM and the **child resource address** is not stable, either:
    
    -   Import to the underlying `azurerm_*` equivalent **or**
        
    -   Comment the import with guidance and generate an `azurerm_*` first pass.
        
-   `outputs.tf` — helpful IDs/names.
    
-   `README.md` — what was generated, how to run, any skipped or cross-RG references, and how AzAPI is used for unknowns.
    

**Relationships**

-   Preserve associations (e.g., subnet ↔ nsg/routeTable/natGateway; webapp ↔ service plan; private endpoint ↔ zone groups) using references.
    

**Safety**

-   No destructive actions. If a default might cause replacement, add a TODO and emit the precise CLI/REST to fetch the real value.
    

## Mapping hints (not exhaustive; prefer AVM when importable)

-   VNets/Subnets → AVM VNet or `azurerm_virtual_network` + `azurerm_subnet`
    
-   NSGs/Rules → `azurerm_network_security_group` + `azurerm_network_security_rule`
    
-   Route tables/Routes → `azurerm_route_table` + `azurerm_route`
    
-   LBs/Rules/Probes/NAT → `azurerm_lb` + children
    
-   App Gateway/children → `azurerm_application_gateway`
    
-   Private DNS/links/records → `azurerm_private_dns_*`
    
-   Private Endpoints/Zone groups → `azurerm_private_endpoint` + `azurerm_private_dns_zone_group`
    
-   Storage, ACR, AKS, KV, App Service → respective `azurerm_*`
    
-   **Anything unknown** → `azapi_resource`
    

## Output format (strict)

1.  Write all files to `${input:target_path:infra\\${input:resource_group}}`.
    
2.  Show a **single consolidated diff/patch** of created/updated files.
    
3.  Provide a compact **runbook**:
    
    1.  `cd ${input:target_path:infra\\${input:resource_group}}`
        
    2.  `terraform init`
        
    3.  `terraform plan` (verify imports; ensure zero-change)
        
    4.  `terraform apply` (only when plan is zero-change)
        

## Performance & scope controls

-   Respect `${input:providers_filter}` to limit namespaces (empty = ALL).
    
-   Use `${input:subresource_depth}` to gate expensive sweeps:
    
    -   `basic`: no deep children; just top-level + a few essentials
        
    -   `network`: include core network children
        
    -   `all`: include full matrix
        
-   Print a summary of counts per **ARM type** at end of discovery.
    

## If tools are missing

-   State which MCP/CLI/REST tools are unavailable.
    
-   Print exact `az`/`az rest` commands (copy-paste ready) I can run manually.
    
-   Proceed using any JSON output I paste back.
    

___

### Quick usage examples

**Scan everything (default strategy):**

```
<div><p>pgsql</p><p><code><span><span>/azure-rg-</span><span><span>to</span></span><span>-terraform: subscription_id=</span><span><span>00000000</span></span><span><span>-0000</span></span><span><span>-0000</span></span><span><span>-0000</span></span><span><span>-000000000000</span></span><span> resource_group=rg-fitcoach-prod subresource_depth=</span><span><span>all</span></span><span> include_subresources=</span><span><span>true</span></span><span>
</span></span></code></p></div>
```

**Scan only selected providers (for speed), still with child sweep:**

```
<div><p>pgsql</p><p><code><span><span>/azure-rg-</span><span><span>to</span></span><span>-terraform: resource_group=rg-fitcoach-prod providers_filter=["Microsoft.Network","Microsoft.Storage","Microsoft.Web"] subresource_depth=</span><span><span>all</span></span><span>
</span></span></code></p></div>
```

**Prefer stable API versions (exclude preview):**

```
<div><p>pgsql</p><p><code><span><span>/azure-rg-</span><span><span>to</span></span><span>-terraform: resource_group=rg-fitcoach-prod api_version_strategy=</span><span><span>stable</span></span><span>
</span></span></code></p></div>
```

```
<div><p>pgsql</p><p><code><span><span>
</span><span><span>If</span></span><span> you </span><span><span>also</span></span><span> want me </span><span><span>to</span></span><span> convert the **instructions.md** link targets </span><span><span>and</span></span><span> examples </span><span><span>to</span></span><span> Windows paths (</span><span><span>and</span></span><span> </span><span><span>add</span></span><span> a PowerShell </span><span><span>version</span></span><span> </span><span><span>of</span></span><span> the quick-</span><span><span>start</span></span><span>), say the word </span><span><span>and</span></span><span> I’ll patch that too.
::contentReference[oaicite:</span><span><span>0</span></span><span>]{</span><span><span>index</span></span><span>=</span><span><span>0</span></span><span>}
</span></span></code></p></div>
```

##### You said:

ok now GitHub copilot have switched from using AVM's for the Terraform to using Azurerm terraform provider for creating the Terraform code for the resources. Can you fix this to prefer AVM's where they are available?

##### You said:

ok now GitHub copilot have switched from using AVM's for the Terraform to using Azurerm terraform provider for creating the Terraform code for the resources. Can you fix this to prefer AVM's where they are available?

###### ChatGPT said:

Absolutely—here’s a **Windows-optimized, AVM-first** drop-in replacement for your prompt file that **forces Copilot to pick AVM modules wherever they exist**, only falling back to `azurerm_*` (or AzAPI) when an AVM module truly isn’t available or importable. It also adds a **validation gate** so the run fails fast if Copilot tries to sneak in plain `azurerm_*` for AVM-covered types.

> Save as: **`.github\prompts\azure-rg-to-terraform.prompt.md`**

```
<div><p>md</p><p><code id="code-lang-md"><span><span>---
mode: agent
<span>description: Deep-scan ALL Azure resources in a resource group via Azure MCP Server and generate Terraform + import blocks using AVM modules by default (strict AVM-first), azurerm fallback only if no AVM exists, AzAPI for unknowns.
---</span>

</span><span><span># Azure RG ➜ Terraform (ALL resources + sub-resources, <span>**AVM-first**</span></span></span><span>)

[</span><span><span>Load detailed rules &amp; mappings</span></span><span>](</span><span><span>..\\instructions\\azure-rg-to-terraform.instructions.md</span></span><span>)

</span><span><span>## Configuration source order (highest precedence first)</span></span><span>
</span><span><span>1.</span></span><span> </span><span><span>**Inline inputs**</span></span><span> when running the prompt (e.g., </span><span><span>`/azure-rg-to-terraform: subscription_id=... resource_group=...`</span></span><span>), referenced via </span><span><span>`${input:...}`</span></span><span> below.
</span><span><span>2.</span></span><span> If a </span><span><span>**JSON inputs file**</span></span><span> is attached as chat context (e.g., </span><span><span>`#file:.copilot\\azure-rg.inputs.json`</span></span><span>), </span><span><span>**parse it**</span></span><span> and use keys as defaults for any inputs not provided inline.
</span><span><span>3.</span></span><span> If anything is still missing, ask me interactively.

</span><span><span>&gt; Example JSON:</span></span><span>
</span><span><span>&gt; ```json</span></span><span>
</span><span><span>&gt; {</span></span><span>
<span>&gt;   "subscription<span>_id": "00000000-0000-0000-0000-000000000000",
&gt;   "resource_</span>group": "rg-fitcoach-prod",</span>
<span>&gt;   "target<span>_path": "infra\\rg-fitcoach-prod",
&gt;   "providers_</span>filter": [],</span>
<span>&gt;   "prefer<span>_avm": true,
&gt;   "avm_</span>enforcement": "strict",</span>
</span><span><span>&gt;   "tf<span>_required_</span></span></span><span>version": "&gt;= 1.6.0",
<span>&gt;   "azurerm<span>_version": "~&gt; 3.113",
&gt;   "azapi_</span>version": "~&gt; 1.13",</span>
<span>&gt;   "location<span>_fallback": "southeastasia",
&gt;   "name_</span>prefix": "fitcoach",</span>
<span>&gt;   "include<span>_subresources": true,
&gt;   "subresource_</span>depth": "all",</span>
</span><span><span>&gt;   "api<span>_version_</span></span></span><span>strategy": "latest"
</span><span><span>&gt; }</span></span><span>
</span><span><span>&gt; ```</span></span><span>

</span><span><span>## Inputs (resolved via `${input:...}`; fall back to JSON when present)</span></span><span>
</span><span><span>-</span></span><span> </span><span><span>**subscription<span>_id**: ${input:subscription_</span></span></span><span>id}
- **resource<span>_group<span>**: ${input:resource_group}
- **</span>target_</span>path** (default </span><span><span>`infra\\${input:resource_group}`</span></span><span>): ${input:target</span><span><span>_path:infra\\${input:resource_</span></span><span>group}}
</span><span><span>-</span></span><span> </span><span><span>**providers<span>_filter** (JSON array; default `[]` for ALL): ${input:providers_</span></span></span><span>filter:[]}
- **prefer</span><span><span>_avm** (default `true`): ${input:prefer_</span></span><span>avm:true}
</span><span><span>-</span></span><span> </span><span><span>**avm<span>_enforcement** (`strict|relaxed`, default `strict`): ${input:avm_</span></span></span><span>enforcement:strict}
- **tf</span><span><span>_required_</span></span><span>version** (default </span><span><span>`&gt;= 1.5.0`</span></span><span>): ${input:tf</span><span><span>_required_</span></span><span>version:&gt;= 1.5.0}
</span><span><span>-</span></span><span> </span><span><span>**azurerm<span>_version** (default `~&gt; 3.113`): ${input:azurerm_</span></span></span><span>version:~&gt; 3.113}
- **azapi</span><span><span>_version** (default `~&gt; 1.13`): ${input:azapi_</span></span><span>version:~&gt; 1.13}
</span><span><span>-</span></span><span> </span><span><span>**location<span>_fallback** (optional): ${input:location_</span></span></span><span>fallback:}
- **name</span><span><span>_prefix** (optional): ${input:name_</span></span><span>prefix:}
</span><span><span>-</span></span><span> </span><span><span>**include<span>_subresources** (default `true`): ${input:include_</span></span></span><span>subresources:true}
- **subresource</span><span><span>_depth** (`basic|network|all`, default `all`): ${input:subresource_</span></span><span>depth:all}
</span><span><span>-</span></span><span> </span><span><span>**api<span>_version_</span></span></span><span>strategy** (</span><span><span>`latest|stable`</span></span><span>, default </span><span><span>`latest`</span></span><span>): ${input:api</span><span><span>_version_</span></span><span>strategy:latest}

---

</span><span><span>## What you will do</span></span><span>
1) Use </span><span><span>**Azure MCP Server**</span></span><span> tools to enumerate </span><span><span>**all**</span></span><span> resources in the target resource group (any provider/namespace), then perform a </span><span><span>**provider-driven child sweep**</span></span><span> so ARM </span><span><span>**sub-resources**</span></span><span> are discovered (e.g., VNets→Subnets, NSGs→Rules, RouteTables→Routes, LBs→Rules/Probes, AppGW children, Private Endpoint DNS zone groups, etc.).
2) Generate </span><span><span>**Terraform**</span></span><span> with an </span><span><span>**AVM-first policy**</span></span><span>:
</span><span><span>   -</span></span><span> </span><span><span>**If an AVM module exists for a resource type, you MUST use it.**</span></span><span>  
</span><span><span>   -</span></span><span> Only if </span><span><span>**no AVM module exists**</span></span><span> (or imports are not feasible) may you use </span><span><span>`azurerm_*`</span></span><span>.
</span><span><span>   -</span></span><span> If the type is unknown/unsupported, use <span>**`azapi<span>_resource`** with correct `type@apiVersion`.
3) Emit **`import` blocks** for *every* discovered object with **`to`** (Terraform address) and **`id`** (full ARM ID).
4) Write files under `${input:target_</span>path:infra\\${input:resource<span>_group}}` and provide a runbook to validate with `terraform plan`.

---

## **AVM-first enforcement &amp; validation (hard rules)**
- **Known AVM-covered types (must not default to `azurerm_</span></span></span><span><span>*`):*</span></span><span>*
  - `Microsoft.Network/virtualNetworks` (and subnets via module inputs or internal child)
  - `Microsoft.Network/networkSecurityGroups` (+ rules)
  - `Microsoft.Network/routeTables` (+ routes)
  - `Microsoft.Network/privateEndpoints` (+ dns zone groups)
  - `Microsoft.Network/loadBalancers` (+ rules/probes/pools)
  - `Microsoft.Network/applicationGateways` (+ listeners/rules/etc.)
  - `Microsoft.Network/natGateways`, `publicIPAddresses`
  - `Microsoft.ContainerRegistry/registries`
  - `Microsoft.KeyVault/vaults`
  - `Microsoft.Storage/storageAccounts`
  - `Microsoft.ContainerService/managedClusters` (AKS)
  - `Microsoft.Web/serverfarms` and `Microsoft.Web/sites` (App Service Plan + Web Apps)
  - `Microsoft.Network/privateDnsZones` (+ vnet links/records)
- **Behavior:**
</span><span><span>  -</span></span><span> If </span><span><span>`${input:avm_enforcement}`</span></span><span> is </span><span><span>`strict`</span></span><span>, </span><span><span>**fail the run and ask for permission**</span></span><span> to continue if any resource from the list above is rendered as </span><span><span>`azurerm_*`</span></span><span> instead of an AVM module.
</span><span><span>  -</span></span><span> Always print a </span><span><span>**summary table**</span></span><span> at the end:
</span><span><span>    -</span></span><span> </span><span><span>`AVM modules used: N`</span></span><span>
</span><span><span>    -</span></span><span> </span><span><span>`azurerm resources used: N`</span></span><span> (with list of types and justification per type)
</span><span><span>    -</span></span><span> </span><span><span>`AzAPI resources used: N`</span></span><span> (with list of types)

</span><span><span>&gt; <span>**Module source selection:**</span></span></span><span> Resolve AVM modules from the Terraform Registry (namespace `Azure`, prefix `avm-res-</span><span><span id="code-lang-xml"><span>&lt;<span>provider</span></span></span></span><span>&gt;-</span><span><span id="code-lang-xml"><span>&lt;<span>resourcename</span></span></span></span><span>&gt;`). Use the most recent </span><span><span>**stable**</span></span><span> release. If registry lookup isn’t available in your toolset, state this and ask me to confirm the module sources or paste them, otherwise </span><span><span>**pause**</span></span><span> (strict mode).

---

</span><span><span>## Tooling inventory (read-only)</span></span><span>
</span><span><span>-</span></span><span> </span><span><span>**Azure CLI via MCP**</span></span><span>:
</span><span><span>  -</span></span><span> </span><span><span>`az account list`</span></span><span>, </span><span><span>`az account set --subscription &lt;id&gt;`</span></span><span>
</span><span><span>  -</span></span><span> </span><span><span>`az resource list -g &lt;rg&gt; --output json`</span></span><span> (generic sweep)
</span><span><span>-</span></span><span> </span><span><span>**ARM REST via MCP**</span></span><span> (for complete child coverage):
</span><span><span>  -</span></span><span> </span><span><span>`GET /subscriptions/{sub}/providers?api-version=2021-04-01`</span></span><span>
</span><span><span>  -</span></span><span> For each resourceType at RG scope, list parents and children; choose API version per </span><span><span>`${input:api_version_strategy}`</span></span><span>.
</span><span><span>-</span></span><span> </span><span><span>**Fallback when tools missing**</span></span><span>: print equivalent </span><span><span>`az`</span></span><span>/</span><span><span>`az rest`</span></span><span> commands; proceed with pasted JSON.

---

</span><span><span>## Discovery algorithm (strict)</span></span><span>
</span><span><span>1.</span></span><span> Resolve/activate subscription.
</span><span><span>2.</span></span><span> Generic sweep: </span><span><span>`az resource list -g &lt;rg&gt;`</span></span><span>.
</span><span><span>3.</span></span><span> Provider child sweep: enumerate provider types at RG scope; expand children for each discovered parent (multi-level chains).
</span><span><span>4.</span></span><span> Deduplicate by </span><span><span>`id`</span></span><span>, keep richest </span><span><span>`properties`</span></span><span>.
</span><span><span>5.</span></span><span> Normalize each object: </span><span><span>`arm_id,name,type,location,tags,parent_id`</span></span><span> + </span><span><span>**minimal TF-critical attributes**</span></span><span> (e.g., SKUs, address spaces, plan/sku for Web Apps, etc.). Track cross-RG references.

---

</span><span><span>## Terraform generation rules (strict AVM-first)</span></span><span>
Create/overwrite under </span><span><span>**`${input:target<span>_path:infra\\${input:resource_</span></span></span><span>group}}`**:

</span><span><span>-</span></span><span> </span><span><span>`versions.tf`</span></span><span>
</span><span><span>  -</span></span><span> use </span><span><span>`${input:tf_required_version}`</span></span><span>; providers: </span><span><span>`azurerm = ${input:azurerm_version}`</span></span><span>, </span><span><span>`azapi = ${input:azapi_version}`</span></span><span>.

</span><span><span>-</span></span><span> </span><span><span>`providers.tf`</span></span><span>
  <span>```hcl
  provider "azurerm" { features {} }
  provider "azapi" {}
  data "azurerm_subscription" "current" {}
  data "azurerm_resource_group" "rg" { name = var.resource_group }
  locals {
    name_prefix = var.name_prefix != "" ? var.name_prefix : var.resource_group
    location    = try(data.azurerm_resource_group.rg.location, var.location_fallback)
  }
</span></span></span></code></p></div>
```

-   `main.tf`
    
    -   **For each object:**
        
        1.  **Try AVM module first.** Use the AVM module’s `source = "Azure/<avm-module>/azurerm"` and set only attributes needed to match real state. Use references (`data.azurerm_resource_group.rg.*`) over literals.
            
        2.  If AVM import isn’t feasible (no stable internal address), either:
            
            -   Add the module but **comment the import guidance**, **or**
                
            -   **Temporarily** use `azurerm_*` with a `TODO: convert to AVM once import stabilized`.
                
        3.  If no AVM or `azurerm_*` exists, use **`azapi_resource`** and pin `type = "<Namespace/Type@<apiVersion>>"`, `parent_id`, `location`, and an empty `body = {}` (with `ignore_changes = [body]`).
            
-   `imports.tf`
    
    ```
    <div><p>hcl</p><p><code id="code-lang-hcl"><span>import {
      to = &lt;RESOURCE ADDRESS&gt;   # module.&lt;name&gt;.&lt;child or exposed&gt; OR azurerm_* OR azapi_resource.*
      id = "&lt;FULL ARM ID&gt;"
    }
    </span></code></p></div>
    ```
    
    -   **AVM imports:** When the module exposes a stable child address, import to it (document address you used). If not, prefer a first-pass `azurerm_*` import and refactor to AVM with `moved` blocks later; explain in README.
        
-   `variables.tf` (min)
    
    ```
    <div><p>hcl</p><p><code id="code-lang-hcl"><span>variable "resource_group" { type = string }
    variable "name_prefix"    { type = string, default = "" }
    variable "location_fallback" { type = string, default = null }
    </span></code></p></div>
    ```
    
-   `outputs.tf` — useful names/ids.
    
-   `README.md` — **must include**:
    
    -   AVM vs azurerm vs AzAPI counts + justification list for any non-AVM in the **covered types** set.
        
    -   Exact commands to reproduce discovery if needed.
        
    -   Notes on imports for AVM modules used (child addresses or first-pass strategy).
        

**Relationships**

-   Use references for associations (subnet ↔ nsg/routeTable/natGateway; webapp ↔ plan; private endpoint ↔ zone groups).
    

**Safety**

-   No destructive or replacing changes; emit TODOs + exact CLI/REST to fetch missing values instead of guessing.
    

___

## Output format (strict)

1.  Write all files to `${input:target_path:infra\\${input:resource_group}}`.
    
2.  Show a **single consolidated diff/patch** of created/updated files.
    
3.  Provide a compact **runbook**:
    
    1.  `cd ${input:target_path:infra\\${input:resource_group}}`
        
    2.  `terraform init`
        
    3.  `terraform plan` (verify imports; ensure zero-change)
        
    4.  `terraform apply` (only when plan is zero-change)
        

___

## Performance & scope controls

-   Respect `${input:providers_filter}` (empty = ALL).
    
-   `${input:subresource_depth}` gates expensive sweeps: `basic | network | all`.
    
-   Print a per-type summary (counts) **and** the AVM/azurerm/AzAPI totals.
    

___

## If tools are missing

-   State which MCP/CLI/REST tools are unavailable.
    
-   Print exact `az`/`az rest` commands (copy-paste ready) I can run manually.
    
-   Proceed using any JSON output I paste back.
    

```
<div><p>pgsql</p><p><code><span><span>
</span><span><span>---</span></span><span>

### What changed (so Copilot behaves)
- **Added `avm_enforcement: </span><span><span>strict</span></span><span>`** + a **covered </span><span><span>types</span></span><span> list** so Copilot must use AVM </span><span><span>for</span></span><span> those services </span><span><span>or</span></span><span> fail the run </span><span><span>with</span></span><span> a justification prompt.
- **Explicit “module source selection” step** (look up AVM module </span><span><span>in</span></span><span> the Terraform Registry; pick latest </span><span><span>stable</span></span><span>).
- **Validation </span><span><span>summary</span></span><span>** requiring **AVM vs azurerm vs AzAPI counts** </span><span><span>and</span></span><span> justifications </span><span><span>for</span></span><span> </span><span><span>any</span></span><span> non-AVM </span><span><span>within</span></span><span> covered </span><span><span>types</span></span><span>.
- **Clear </span><span><span>import</span></span><span> guidance** </span><span><span>for</span></span><span> AVM (use exposed child addresses </span><span><span>when</span></span><span> </span><span><span>stable</span></span><span>; otherwise first-pass `azurerm_*` </span><span><span>then</span></span><span> refactor).

</span><span><span>If</span></span><span> you want, I can </span><span><span>also</span></span><span> patch your `..\\instructions\\azure-rg-</span><span><span>to</span></span><span>-terraform.instructions.md` </span><span><span>to</span></span><span> </span><span><span>include</span></span><span> a quick **AVM module lookup recipe** (names/patterns + example module addresses) </span><span><span>and</span></span><span> a short checklist that Copilot must satisfy </span><span><span>before</span></span><span> emitting </span><span><span>any</span></span><span> `azurerm_*` </span><span><span>for</span></span><span> the covered services.
::contentReference[oaicite:</span><span><span>0</span></span><span>]{</span><span><span>index</span></span><span>=</span><span><span>0</span></span><span>}
</span></span></code></p></div>
```

##### You said:

Copilot still does not locate the input.jason withtis prompt - I get this in the response - "To proceed, I need the following required inputs for the Azure resource group deep scan and Terraform generation: subscription\_id (Azure subscription GUID) resource\_group (name of the resource group to scan) You can provide these inline, or attach a JSON inputs file as described in the prompt. If you want to use defaults for other options, just provide the two required values. Please supply the values to continue."

###### ChatGPT said:

You’re running into a Copilot limitation: **`${input:...}` variables can’t be auto-filled from a file**. If a prompt contains required `${input:...}` with no defaults, Copilot will always ask for them—even if you attach JSON.

Fix: give every `${input:...}` a **sentinel default** (e.g., `__auto__`) and add a **must-follow input resolution algorithm** so the agent reads your attached JSON when the sentinel is present.

Below is a **drop-in Windows version** of your prompt that does exactly that. With this, you can attach your `.copilot\azure-rg.inputs.json` (paperclip or `#file:.copilot/azure-rg.inputs.json`) and run the prompt **without** inline args.

> Save as: **`.github\prompts\azure-rg-to-terraform.prompt.md`**

```
<div><p>md</p><p><code id="code-lang-md"><span><span>---
mode: agent
<span>description: Deep-scan ALL Azure resources in a resource group via Azure MCP Server and generate Terraform + import blocks using AVM modules by default (strict AVM-first), azurerm fallback only if no AVM exists, AzAPI for unknowns.
---</span>

</span><span><span># Azure RG ➜ Terraform (ALL resources + sub-resources, <span>**AVM-first**</span></span></span><span>)

[</span><span><span>Load detailed rules &amp; mappings</span></span><span>](</span><span><span>..\\instructions\\azure-rg-to-terraform.instructions.md</span></span><span>)

</span><span><span>## Input Resolution (must do in this exact order)</span></span><span>
You will resolve inputs using this algorithm:

1) Read the inline </span><span><span>`${input:...}`</span></span><span> values below. If a value is </span><span><span>**not**</span></span><span> </span><span><span>`__auto__`</span></span><span>, use it.
2) If a value </span><span><span>**is**</span></span><span> </span><span><span>`__auto__`</span></span><span>, check whether a JSON file is attached in chat context (e.g., via the paperclip or </span><span><span>`#file:.copilot/azure-rg.inputs.json`</span></span><span>).  
</span><span><span>   -</span></span><span> If present, </span><span><span>**parse it**</span></span><span> and use the value from the JSON if available.
3) If still </span><span><span>`__auto__`</span></span><span> after step 2, compute a sane default </span><span><span>**only where noted**</span></span><span> below; otherwise </span><span><span>**ask me once**</span></span><span> for the missing value.

</span><span><span>&gt; Example JSON schema:</span></span><span>
</span><span><span>&gt; ```json</span></span><span>
</span><span><span>&gt; {</span></span><span>
<span>&gt;   "subscription<span>_id": "00000000-0000-0000-0000-000000000000",
&gt;   "resource_</span>group": "rg-fitcoach-prod",</span>
<span>&gt;   "target<span>_path": "infra\\rg-fitcoach-prod",
&gt;   "providers_</span>filter": [],</span>
<span>&gt;   "prefer<span>_avm": true,
&gt;   "avm_</span>enforcement": "strict",</span>
</span><span><span>&gt;   "tf<span>_required_</span></span></span><span>version": "&gt;= 1.6.0",
<span>&gt;   "azurerm<span>_version": "~&gt; 3.113",
&gt;   "azapi_</span>version": "~&gt; 1.13",</span>
<span>&gt;   "location<span>_fallback": "southeastasia",
&gt;   "name_</span>prefix": "fitcoach",</span>
<span>&gt;   "include<span>_subresources": true,
&gt;   "subresource_</span>depth": "all",</span>
</span><span><span>&gt;   "api<span>_version_</span></span></span><span>strategy": "latest"
</span><span><span>&gt; }</span></span><span>
</span><span><span>&gt; ```</span></span><span>

</span><span><span>## Inputs (every one has a sentinel default to avoid Copilot prompts)</span></span><span>
</span><span><span>-</span></span><span> </span><span><span>**subscription<span>_id**: ${input:subscription_</span></span></span><span>id:_</span><span><span>_auto_</span></span><span><span>_}  &lt;!-- required, no computed default --&gt;
- **resource_</span>group**: ${input:resource</span><span><span>_group:<span>__auto__</span></span></span><span>}    &lt;!-- required, no computed default --&gt;
- </span><span><span>**target_path**</span></span><span>: ${input:target_path:</span><span><span>__auto__</span></span><span>}          &lt;!-- if </span><span><span>__auto__</span></span><span>, compute as </span><span><span>`infra\\&lt;resource_group&gt;`</span></span><span> --&gt;
</span><span><span>-</span></span><span> </span><span><span>**providers<span>_filter** (JSON array): ${input:providers_</span></span></span><span>filter:_</span><span><span>_auto_</span></span><span><span>_}  &lt;!-- if _</span></span><span><span>_auto_</span></span><span><span>_, default to [] --&gt;
- **prefer_</span>avm**: ${input:prefer</span><span><span>_avm:<span>__auto__</span></span></span><span>}            &lt;!-- if </span><span><span>__auto__</span></span><span>, default to true --&gt;
- </span><span><span>**avm_enforcement**</span></span><span> (`strict|relaxed`): ${input:avm_enforcement:</span><span><span>__auto__</span></span><span>}  &lt;!-- if </span><span><span>__auto__</span></span><span>, default to strict --&gt;
</span><span><span>-</span></span><span> </span><span><span>**tf<span>_required_</span></span></span><span>version**: ${input:tf</span><span><span>_required_</span></span><span>version:</span><span><span>__auto__</span></span><span>}   &lt;!-- if </span><span><span>__auto__</span></span><span>, default to &gt;= 1.5.0 --&gt;
</span><span><span>-</span></span><span> </span><span><span>**azurerm<span>_version**: ${input:azurerm_</span></span></span><span>version:_</span><span><span>_auto_</span></span><span><span>_}           &lt;!-- if _</span></span><span><span>_auto_</span></span><span><span>_, default to ~&gt; 3.113 --&gt;
- **azapi_</span>version**: ${input:azapi</span><span><span>_version:<span>__auto__</span></span></span><span>}               &lt;!-- if </span><span><span>__auto__</span></span><span>, default to ~&gt; 1.13 --&gt;
- </span><span><span>**location_fallback**</span></span><span>: ${input:location_fallback:</span><span><span>__auto__</span></span><span>}       &lt;!-- optional --&gt;
</span><span><span>-</span></span><span> </span><span><span>**name<span>_prefix**: ${input:name_</span></span></span><span>prefix:_</span><span><span>_auto_</span></span><span><span>_}                   &lt;!-- optional --&gt;
- **include_</span>subresources**: ${input:include</span><span><span>_subresources:<span>__auto__</span></span></span><span>} &lt;!-- if </span><span><span>__auto__</span></span><span>, default to true --&gt;
- </span><span><span>**subresource_depth**</span></span><span> (`basic|network|all`): ${input:subresource_depth:</span><span><span>__auto__</span></span><span>}  &lt;!-- if </span><span><span>__auto__</span></span><span>, default to all --&gt;
</span><span><span>-</span></span><span> </span><span><span>**api<span>_version_</span></span></span><span>strategy** (</span><span><span>`latest|stable`</span></span><span>): ${input:api</span><span><span>_version_</span></span><span>strategy:</span><span><span>__auto__</span></span><span>} &lt;!-- if </span><span><span>__auto__</span></span><span>, default to latest --&gt;

</span><span><span>&gt; After resolving:</span></span><span>
</span><span><span>&gt; - If `subscription<span>_id` or `resource_</span></span></span><span>group` remain `</span><span><span>__auto__</span></span><span>`, ask me </span><span><span>**once**</span></span><span> for those two values only.
</span><span><span>&gt; - If `target<span>_path` is `<span>__auto__</span></span></span></span><span>`, set to `infra\\</span><span><span id="code-lang-xml"><span>&lt;<span>resource_group</span></span></span></span><span>&gt;`.

## What you will do
1) Use </span><span><span>**Azure MCP Server**</span></span><span> tools to enumerate </span><span><span>**all**</span></span><span> resources in the target RG (any provider/namespace), then perform a </span><span><span>**provider-driven child sweep**</span></span><span> so ARM </span><span><span>**sub-resources**</span></span><span> are discovered (VNets→Subnets, NSGs→Rules, RTs→Routes, LBs→Rules/Probes, AppGW children, Private Endpoint DNS zone groups, etc.).
2) Generate </span><span><span>**Terraform**</span></span><span> with an </span><span><span>**AVM-first**</span></span><span> policy:
   - If an </span><span><span>**AVM**</span></span><span> module exists for a type, </span><span><span>**use it**</span></span><span>.
   - Else use </span><span><span>**`azurerm_*`**</span></span><span>.
   - If unknown/unsupported, use </span><span><span>**`azapi_resource`**</span></span><span> with `type@apiVersion`.
3) Emit </span><span><span>**`import` blocks**</span></span><span> for *every* object with </span><span><span>**`to`**</span></span><span> (Terraform address) and </span><span><span>**`id`**</span></span><span> (full ARM ID).
4) Write files under the final `target_path` (resolved above) and provide a runbook to validate with `terraform plan`.

</span><span><span>## AVM-first enforcement</span></span><span>
</span><span><span>-</span></span><span> Covered AVM types (must not default to </span><span><span>`azurerm_*`</span></span><span> unless justified): VNets/Subnets, NSGs/Rules, RouteTables/Routes, Private Endpoints/Zone groups, LBs (+children), App Gateways (+children), NAT Gateways, Public IPs, ACR, AKS, Key Vault, Storage, App Service Plan/Web Apps, Private DNS (+links/records).
</span><span><span>-</span></span><span> If enforcement mode is </span><span><span>`strict`</span></span><span>, </span><span><span>**stop and ask**</span></span><span> if any covered type is rendered as plain </span><span><span>`azurerm_*`</span></span><span> without justification.
</span><span><span>-</span></span><span> End with a summary: counts for AVM vs azurerm vs AzAPI, with justifications for any non-AVM in covered types.

</span><span><span>## Tooling (read-only)</span></span><span>
</span><span><span>-</span></span><span> Azure CLI via MCP: </span><span><span>`az account list`</span></span><span>, </span><span><span>`az account set --subscription &lt;id&gt;`</span></span><span>, </span><span><span>`az resource list -g &lt;rg&gt; --output json`</span></span><span>.
</span><span><span>-</span></span><span> ARM REST via MCP:
</span><span><span>  -</span></span><span> </span><span><span>`GET /subscriptions/{sub}/providers?api-version=2021-04-01`</span></span><span>
</span><span><span>  -</span></span><span> List each RG-scoped resourceType; for child types, iterate discovered parents to list children. Choose api-version based on </span><span><span>`api_version_strategy`</span></span><span>.
</span><span><span>-</span></span><span> If tools missing: print equivalent </span><span><span>`az`</span></span><span>/</span><span><span>`az rest`</span></span><span> commands; proceed with pasted JSON.

</span><span><span>## Discovery algorithm</span></span><span>
</span><span><span>1.</span></span><span> Resolve subscription; set context.
</span><span><span>2.</span></span><span> Generic sweep: </span><span><span>`az resource list -g &lt;rg&gt;`</span></span><span>.
</span><span><span>3.</span></span><span> Provider child sweep: enumerate provider types at RG scope; expand children (including multi-level).
</span><span><span>4.</span></span><span> Deduplicate by </span><span><span>`id`</span></span><span>; keep richest properties.
</span><span><span>5.</span></span><span> Normalize: </span><span><span>`arm_id,name,type,location,tags,parent_id`</span></span><span> + minimal TF-critical attrs; track cross-RG references.

</span><span><span>## Terraform generation (AVM-first)</span></span><span>
Create/overwrite under </span><span><span>**`<span id="code-lang-xml"><span>&lt;<span>target_path</span></span></span></span></span><span>&gt;`**:
</span><span><span>-</span></span><span> </span><span><span>`versions.tf`</span></span><span> (providers: azurerm, azapi with versions).
</span><span><span>-</span></span><span> </span><span><span>`providers.tf`</span></span><span> (</span><span><span>`provider "azurerm" { features {} }`</span></span><span>, </span><span><span>`provider "azapi" {}`</span></span><span>, data sources for subscription &amp; RG, locals for location &amp; name<span>_prefix).
- `main.tf`
  - Prefer </span></span><span><span>**AVM**</span></span><span> module: `source = "Azure/</span><span><span id="code-lang-xml"><span>&lt;<span>avm-module</span></span></span></span><span>&gt;/azurerm"`.
  - Else `azurerm_<span>*`.
  - Else `azapi_resource`:
    ```hcl
    resource "azapi_resource" "</span></span><span><span id="code-lang-xml"><span>&lt;<span>name</span></span></span></span><span>&gt;" {
      type      = "</span><span><span id="code-lang-xml">&lt;Namespace/Type@<span>&lt;<span>apiVersion</span></span></span></span><span>&gt;&gt;"
      name      = "</span><span><span id="code-lang-xml"><span>&lt;<span>name</span></span></span></span><span>&gt;"
      parent_id = "</span><span><span id="code-lang-xml"><span>&lt;<span>parent</span></span></span></span><span> </span><span><span>ARM</span></span><span> </span><span><span>id</span></span><span> </span><span><span>or</span></span><span> </span><span><span>data.azurerm_resource_group.rg.id</span></span><span>&gt;"
      location  = local.location
      body      = {}
      lifecycle { ignore_changes = [body] }
    }
    ```
- `imports.tf` — one block per object:
  ```hcl
  import {
    to = </span><span><span id="code-lang-xml"><span>&lt;<span>RESOURCE</span></span></span></span><span> </span><span><span>ADDRESS</span></span><span>&gt;
    id = "</span><span><span id="code-lang-xml"><span>&lt;<span>FULL</span></span></span></span><span> </span><span><span>ARM</span></span><span> </span><span><span>ID</span></span><span>&gt;"
  }
</span></span></code></p></div>
```

-   For AVM: import to exposed child address if stable; otherwise note first-pass `azurerm_*` import then refactor.
    
-   `variables.tf`, `outputs.tf`, `README.md` (what, how to run, skipped items, import notes).
    

## Output format

1.  Write all files to `<target_path>`.
    
2.  Show a single consolidated diff/patch.
    
3.  Runbook:
    
    1.  `cd <target_path>`
        
    2.  `terraform init`
        
    3.  `terraform plan`
        
    4.  `terraform apply` (only when plan is zero-change)
        

## Performance & scope

-   Respect `providers_filter` (empty = ALL).
    
-   Use `subresource_depth` to cap sweeps: `basic | network | all`.
    
-   Print per-type counts and AVM/azurerm/AzAPI totals.
    

## If tools are missing

-   State which tools are unavailable.
    
-   Print exact `az`/`az rest` commands (copy-paste ready).
    
-   Proceed using any JSON I paste back.
    

```
<div><p>yaml</p><p><code><span><span>
<span>---
</span>
</span><span><span>### How to run (Windows)</span></span><span>

</span><span><span>1</span></span><span><span>)</span></span><span> </span><span><span>Create</span></span><span> </span><span><span>your</span></span><span> </span><span><span>defaults</span></span><span> </span><span><span>file</span></span><span> </span><span><span>(if</span></span><span> </span><span><span>you</span></span><span> </span><span><span>haven’t</span></span><span> </span><span><span>already):</span></span><span>

</span></span></code></p></div>
```

## in a terminal at your repo root

mkdir .copilot 2> NUL  
notepad .copilot\\azure-rg.inputs.json

```
<div><p>markdown</p><p><code><span><span>
Paste your JSON, save.

2) In </span><span><span>**Copilot Chat**</span></span><span>:
</span><span><span>-</span></span><span> Click the </span><span><span>**paperclip**</span></span><span> and attach </span><span><span>`.copilot\azure-rg.inputs.json`</span></span><span> (or type: </span><span><span>`#file:.copilot/azure-rg.inputs.json`</span></span><span> — forward slashes work in chat references).
</span><span><span>-</span></span><span> Run:  
</span></span></code></p></div>
```

/azure-rg-to-terraform

```
<div><p>pgsql</p><p><code><span><span>(</span><span><span>No</span></span><span> </span><span><span>inline</span></span><span> args needed. The sentinel `__auto__` </span><span><span>values</span></span><span> will make the agent </span><span><span>read</span></span><span> your </span><span><span>JSON</span></span><span>. </span><span><span>If</span></span><span> `subscription_id`/`resource_group` are missing it will ask </span><span><span>only</span></span><span> </span><span><span>for</span></span><span> those.)

</span><span><span>If</span></span><span> you want, I can </span><span><span>also</span></span><span> patch the **instructions.md** </span><span><span>to</span></span><span> echo this “sentinel + file” mechanism </span><span><span>and</span></span><span> </span><span><span>add</span></span><span> a small validation checklist Copilot must print </span><span><span>before</span></span><span> proceeding.
::contentReference[oaicite:</span><span><span>0</span></span><span>]{</span><span><span>index</span></span><span>=</span><span><span>0</span></span><span>}
</span></span></code></p></div>
```

##### You said:

Ok that is working well. One more this, when I run the prompt the copilot, the copilot keeps asking for me to click continue before running the task, how do I make copilot run all the tasks without prompting for verification at each task

###### ChatGPT said:

Yep — you can make Copilot run straight through by (1) auto-approving tools/commands and (2) raising the “keep going?” limit.

### Fastest (but risky): auto-approve everything

Add this to your VS Code **Settings (JSON)** (User or Workspace):

```
<div><p>json</p><p><code id="code-lang-json"><span><span><span>{</span></span><span>
  </span><span><span>// Don't ask before running tools or terminal commands</span></span><span>
  </span><span><span>"chat.tools.global.autoApprove"</span></span><span><span>:</span></span><span> </span><span><span><span>true</span></span></span><span></span><span><span>,</span></span><span>

  </span><span><span>// Let the agent run longer before it asks "Continue?"</span></span><span>
  </span><span><span>"chat.agent.maxRequests"</span></span><span><span>:</span></span><span> </span><span><span>250</span></span><span>
</span><span><span>}</span></span><span>
</span></span></code></p></div>
```

-   `chat.tools.global.autoApprove` disables manual approvals for _all_ tools and terminal commands. Use only if you fully trust your setup. [Visual Studio Code](https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode)
    
-   `chat.agent.maxRequests` bumps the step limit (default is much lower), so the “Continue?” dialog shows up far less often. [Visual Studio Code](https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode)
    

### Safer: allow-list terminal commands, block destructive ones

If you’d rather keep some guardrails, use a per-command allow/deny list:

```
<div><p>json</p><p><code id="code-lang-json"><span><span><span>{</span></span><span>
  </span><span><span>// Approve safe read-only commands; block destructive verbs</span></span><span>
  </span><span><span>"chat.tools.terminal.autoApprove"</span></span><span><span>:</span></span><span> </span><span><span>{</span></span><span>
    </span><span><span>// Allow common read-only az commands</span></span><span>
    </span><span><span>"/^az (account|resource|network|acr|aks|keyvault|storage|webapp) (list|show)\\b/"</span></span><span><span>:</span></span><span> </span><span><span><span>true</span></span></span><span></span><span><span>,</span></span><span>
    </span><span><span>"/^az rest\\b.*--method GET\\b/"</span></span><span><span>:</span></span><span> </span><span><span><span>true</span></span></span><span></span><span><span>,</span></span><span>

    </span><span><span>// Block destructive verbs everywhere</span></span><span>
    </span><span><span>"/\\b(delete|remove|purge|stop|deallocate|update|set-policy|set-permissions)\\b/i"</span></span><span><span>:</span></span><span> </span><span><span><span>false</span></span></span><span></span><span><span>,</span></span><span>
    </span><span><span>"rm"</span></span><span><span>:</span></span><span> </span><span><span><span>false</span></span></span><span></span><span><span>,</span></span><span>
    </span><span><span>"del"</span></span><span><span>:</span></span><span> </span><span><span><span>false</span></span></span><span>
  </span><span><span>}</span></span><span><span>,</span></span><span>
  </span><span><span>"chat.agent.maxRequests"</span></span><span><span>:</span></span><span> </span><span><span>250</span></span><span>
</span><span><span>}</span></span><span>
</span></span></code></p></div>
```

This approves the discovery calls your prompt makes (e.g., `az resource list`) without you clicking each time, while still denying deletes/updates. You can expand the allow list as needed. [Visual Studio Code](https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode)

### One-click trust per tool (good middle ground)

When a tool confirmation pops up, use the **Allow ▾** dropdown → **Always allow** (for this workspace or forever). That permanently suppresses prompts for that tool. You can reset confirmations later with **Chat: Reset Tool Confirmations**. [Visual Studio Code](https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode)

> Heads-up: There’s also `chat.tools.autoApprove` (experimental) and file-edit auto-approval (`chat.tools.edits.autoApprove`), but for your RG scanner the key bits are `chat.tools.global.autoApprove` / `chat.tools.terminal.autoApprove` and `chat.agent.maxRequests`. [Visual Studio Code](https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode)

If you want, tell me your current prompt behavior and I’ll give you a minimal settings JSON tailored to your exact MCP tools and commands.

ChatGPT can make mistakes. Check important info.