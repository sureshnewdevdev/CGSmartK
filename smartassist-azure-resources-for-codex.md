# SmartAssist AI Azure Resources — Codex Development Context

> Prepared for the SmartAssist AI Knowledge Assistant. This document excludes API keys, access keys, secrets, tokens and secret-bearing connection-string values.

## Instructions for Codex

- Build an ASP.NET Core 8 MVC knowledge-assistant application using the existing Azure resources listed below.
- Do not create, rename or delete Azure resources.
- Use `DefaultAzureCredential` with the App Service system-assigned managed identity.
- Do not put credentials in source code or `appsettings.json`.
- Use the existing Web App application-setting names.
- Implement RAG: PDF upload → extraction → chunking → embeddings → Azure AI Search → grounded response with citations.

## Azure account and deployment scope

| Property | Value |
|---|---|
| Subscription | Visual Studio Enterprise |
| Subscription ID | `bae405f7-48fe-48ae-a393-b10c8205792d` |
| Tenant | Default Directory |
| Tenant ID | `b24388d9-c6ca-4c64-a601-5edb6e666e1e` |
| Resource group | `SmartApp` |
| Region | `centralus` / Central US |
| Deterministic suffix | `f59ee617` |
| Environment | Development/training |

## Resources created

| Azure resource | Name | Purpose | Important details |
|---|---|---|---|
| Resource Group | `SmartApp` | Contains the complete solution infrastructure | Central US |
| Storage Account | `stsmartappf59ee617` | Stores approved source PDFs | StorageV2, Standard_LRS, private access, HTTPS/TLS 1.2 |
| Blob Container | `knowledge-documents` | Source documents for ingestion | Private container |
| Key Vault | `kv-smartapp-f59ee617` | Optional secrets/certificates | Standard, RBAC authorization, purge protection |
| Azure AI Search | `srch-smartapp-f59ee617` | Vector/hybrid retrieval for RAG | Basic, one replica, one partition, system identity |
| Azure OpenAI | `aoai-smartapp-f59ee617` | Chat completion and embeddings | S0, system identity |
| Document Intelligence | `docint-smartapp-f59ee617` | PDF text and layout extraction | FormRecognizer, S0, system identity |
| Log Analytics | `log-smartapp-f59ee617` | Central application/operation logs | 30-day retention |
| Application Insights | `appi-smartapp-f59ee617` | ASP.NET request, dependency and exception telemetry | Workspace-based |
| App Service Plan | `asp-smartapp-f59ee617` | Linux compute for the web application | B1 |
| Web App | `web-smartapp-f59ee617` | Hosts the ASP.NET Core 8 application | Linux, HTTPS only, system-assigned identity |

## Safe endpoints and identifiers

| Component | Value |
|---|---|
| Web application URL | `https://web-smartapp-f59ee617.azurewebsites.net` |
| Web App managed-identity principal ID | `41f3cdfc-208c-4f4a-8660-34eb21aa9390` |
| Blob service endpoint | `https://stsmartappf59ee617.blob.core.windows.net/` |
| Blob container | `knowledge-documents` |
| Key Vault URI | `https://kv-smartapp-f59ee617.vault.azure.net/` |
| Azure AI Search endpoint | `https://srch-smartapp-f59ee617.search.windows.net` |
| Search index to create | `smartassist-knowledge-index` |
| Azure OpenAI resource | `aoai-smartapp-f59ee617` |
| Document Intelligence resource | `docint-smartapp-f59ee617` |

The precise Azure OpenAI and Document Intelligence endpoints should be read from the Web App settings or exported with `08-export-codex-resource-context.ps1`. Do not guess endpoint domains in application code.

## Azure OpenAI model deployments

| Deployment name | Model | Version | Deployment SKU | Use |
|---|---|---|---|---|
| `smartassist-chat` | `gpt-5.4-mini` | `2026-03-17` | `GlobalStandard` | Grounded answer generation |
| `smartassist-embedding` | `text-embedding-3-small` | `1` | Use the successfully selected SKU reported by Azure | Document/query embeddings |

The application must reference the **deployment names**, not only the underlying model names.

## Expected managed-identity RBAC assignments

Principal: Web App system-assigned identity `41f3cdfc-208c-4f4a-8660-34eb21aa9390`.

| Role | Scope |
|---|---|
| Storage Blob Data Contributor | `stsmartappf59ee617` |
| Key Vault Secrets User | `kv-smartapp-f59ee617` |
| Search Service Contributor | `srch-smartapp-f59ee617` |
| Search Index Data Contributor | `srch-smartapp-f59ee617` |
| Cognitive Services OpenAI User | `aoai-smartapp-f59ee617` |
| Cognitive Services User | `docint-smartapp-f59ee617` |

Run `05-configure-rbac.ps1` successfully before depending on these assignments. Azure role propagation may take several minutes.

## Web App application-setting contract

The deployment scripts configure these setting names. Codex should bind them through ASP.NET Core configuration.

| Setting | Purpose |
|---|---|
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Application Insights telemetry |
| `SmartAssist__AzureOpenAI__Endpoint` | Azure OpenAI endpoint |
| `SmartAssist__AzureOpenAI__ChatDeployment` | `smartassist-chat` |
| `SmartAssist__AzureOpenAI__EmbeddingDeployment` | `smartassist-embedding` |
| `SmartAssist__Search__Endpoint` | Azure AI Search endpoint |
| `SmartAssist__Search__IndexName` | `smartassist-knowledge-index` |
| `SmartAssist__Storage__AccountName` | `stsmartappf59ee617` |
| `SmartAssist__Storage__ContainerName` | `knowledge-documents` |
| `SmartAssist__DocumentIntelligence__Endpoint` | Document Intelligence endpoint |
| `SmartAssist__KeyVault__Uri` | Key Vault URI |
| `ASPNETCORE_ENVIRONMENT` | `Production` |

Do not copy secret values into this document. Read settings from the App Service environment at runtime.

## Suggested .NET solution

```text
SmartAssist.sln
├── SmartAssist.Web
├── SmartAssist.Application
├── SmartAssist.Domain
├── SmartAssist.Infrastructure
└── SmartAssist.Tests
```

Recommended packages:

- `Azure.Identity`
- `Azure.Storage.Blobs`
- `Azure.Search.Documents`
- `Azure.AI.OpenAI`
- `Azure.AI.DocumentIntelligence`
- `Azure.Security.KeyVault.Secrets`
- `Microsoft.ApplicationInsights.AspNetCore`

## Development work still required

1. Create the ASP.NET Core 8 MVC solution.
2. Implement administrator PDF upload and document management.
3. Store approved PDFs in `knowledge-documents`.
4. Extract text and layout through Document Intelligence.
5. Split text into chunks with document name, page number and source metadata.
6. Generate vectors through `smartassist-embedding`.
7. Create and populate `smartassist-knowledge-index`.
8. Build the employee chat page.
9. Retrieve relevant chunks through vector/hybrid search.
10. Send retrieved context to `smartassist-chat`.
11. Return grounded responses with document/page citations.
12. Add validation, error handling, telemetry and automated tests.
13. Deploy the application to `web-smartapp-f59ee617`.

## Security requirements

- Never provide Codex with Azure access keys, API keys, client secrets, tokens or complete secret-bearing connection strings.
- Use managed identity and Azure RBAC.
- Keep the Blob container private.
- Validate PDF type, size and content before processing.
- Treat document text as untrusted input and defend against prompt injection.
- Require citations for generated answers.
- Do not log credentials, access tokens or sensitive document contents.

## Optional setup

Microsoft Entra App Service authentication is optional for the first MVP. Enable it later using `07-configure-entra-authentication-optional.ps1` after confirming tenant app-registration policy.

## Live verification

Run these scripts before giving the final context to Codex:

```powershell
.\05-configure-rbac.ps1
.\06-verify-resources.ps1
.\08-export-codex-resource-context.ps1
```

The final command generates a fresh `smartassist-azure-resources-for-codex.md` from the live Azure deployment and excludes secret values.
