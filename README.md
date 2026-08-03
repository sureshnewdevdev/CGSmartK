# SmartAssist AI (CGSmartK)

SmartAssist AI is a .NET 8 MVC knowledge assistant. Knowledge Administrators approve PDFs; a bounded worker stores and extracts them, creates token-aware chunks and embeddings, and indexes them in Azure AI Search. Employees receive only grounded answers with verified page citations, deterministic confidence, UTC timestamp, and correlation ID.

## Architecture and flows

```mermaid
flowchart LR
 A[Admin PDF] --> V[Signature, size, hash validation] --> B[Private Blob] --> Q[Bounded worker] --> D[Document Intelligence layout] --> C[800-token chunks / 120 overlap] --> E[Azure OpenAI embeddings] --> S[AI Search vector index]
```
```mermaid
flowchart LR
 U[Authenticated employee] --> Z[Validate and authorize] --> H[Hybrid/vector query + ACL filter] --> P[Authorized passages] --> O[Grounded Azure OpenAI prompt] --> G[Citation/policy validator] --> R[Answer or safe fallback]
```

Clean Architecture projects are `src/CGSmartK.Domain` (rules), `Application` (use cases/contracts), `Infrastructure` (managed-identity Azure adapters, worker, MCP boundary), and `Web` (MVC/auth/UI). Tests under `tests/` cover core behavior, MVC protection, and dependency direction. See [architecture](docs/architecture.md).

## Prerequisites and setup

Install .NET 8 SDK, PowerShell 7, and Azure CLI. On Windows/PowerShell:

```powershell
az login --tenant b24388d9-c6ca-4c64-a601-5edb6e666e1e
az account set --subscription bae405f7-48fe-48ae-a393-b10c8205792d
./scripts/Test-Prerequisites.ps1
./scripts/Configure-LocalDevelopment.ps1
dotnet run --project src/CGSmartK.Web
```

`DefaultAzureCredential` uses Azure CLI developer credentials locally and the App Service system-assigned identity in Azure; no keys are supported. Development authentication creates `dev-employee`; add `?as=admin` to a URL for `dev-admin`. This handler is selected only in Development. Upload a synthetic PDF as admin, wait for Indexed, then ask a supported question. The demo fixture is not a company policy.

## Configuration contract

Environment variables use `__` in App Service and map to the shown `:` paths.

| Setting | Required | Secret? | Safe default/purpose |
|---|---:|---:|---|
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Production | Yes | Set only in App Service |
| `SmartAssist:AzureOpenAI:Endpoint` | Yes | No | Queried by setup; intentionally blank in source |
| `SmartAssist:AzureOpenAI:ChatDeployment` | Yes | No | `smartassist-chat` |
| `SmartAssist:AzureOpenAI:EmbeddingDeployment` | Yes | No | `smartassist-embedding` |
| `SmartAssist:Search:Endpoint` | Yes | No | Existing Search endpoint |
| `SmartAssist:Search:IndexName` | Yes | No | `smartassist-knowledge-index` |
| `SmartAssist:Storage:AccountName` / `ContainerName` | Yes | No | Existing account/private container |
| `SmartAssist:DocumentIntelligence:Endpoint` | Yes | No | Queried; intentionally blank in source |
| `SmartAssist:KeyVault:Uri` | Yes | No | Existing vault URI |
| `ASPNETCORE_ENVIRONMENT` | Yes | No | `Development` locally, `Production` in Azure |
| `SmartAssist:Mcp:*` | No | endpoint no; auth yes | Disabled by default |

Non-secret ingestion/retrieval values are in `appsettings.json`. Never populate source files with credentials.

## Build, test, and deploy

```powershell
dotnet restore CGSmartK.sln
dotnet build CGSmartK.sln --configuration Release --no-restore
dotnet test CGSmartK.sln --configuration Release --no-build
./scripts/Test-AzureAccess.ps1
./scripts/Deploy-WebApp.ps1 -ConfirmDeployment
```

Deployment uses the caller's Azure login and existing Web App only. The script never creates resources. Live smoke operations are opt-in because they can touch data-plane objects.

## Authentication and remaining owner setup

Production fails closed unless App Service Authentication forwards a principal. The owner must create an Entra app registration, configure redirect URI `https://web-smartapp-f59ee617.azurewebsites.net/.auth/login/aad/callback`, expose/consent required scopes, assign Employee/KnowledgeAdministrator app roles or group mappings, configure App Service Authentication with tenant/client ID, require authentication, and preserve the Easy Auth principal headers. No client ID exists in this repository.

MCP is not required. Configure a real allowlisted endpoint and workload-identity/managed-identity authentication as described in [MCP integration](docs/mcp-integration.md). The current adapter is disabled; synthetic output is explicitly labeled and development-only.

## Operations, security, and limits

Health endpoints are `/health/live` and `/health/ready`; anonymous responses contain no resource identifiers. Logs contain IDs, counts, result codes, and durations—not document text, prompts, answers, tokens, or personal details. Search applies classification/group filters before context construction. Blob links are never public.

The bounded in-process queue is appropriate only for one B1 instance: restarts can lose queued work although document metadata survives. At scale, replace it with Azure Storage Queue/Service Bus and an independent worker. See [operations](docs/operations.md), [security](docs/security.md), and [Azure inventory](docs/azure-resources.md).

Troubleshooting: allow RBAC propagation and verify exact roles with `Test-AzureAccess.ps1`; update configured deployment names if a model retires; treat vector dimension/index incompatibility as a controlled migration rather than destructive replacement; malformed/encrypted PDFs fail with a correlation ID; dependency outages return a safe fallback and never invoke ungrounded generation.
