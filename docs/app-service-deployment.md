# Deploy to the existing Azure App Service

This runbook deploys the application to the existing `web-smartapp-f59ee617` Web App. It does not create or delete application resources. Run the commands in PowerShell 7 from the repository root. You need permission to deploy to the Web App, update its settings, and inspect its managed identity. An Azure administrator must perform any missing RBAC or Microsoft Entra configuration.

## 1. Install tools and sign in

Install the [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0), [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell), and [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli). Then select the tenant and subscription containing the existing resources:

```powershell
az login --tenant b24388d9-c6ca-4c64-a601-5edb6e666e1e
az account set --subscription bae405f7-48fe-48ae-a393-b10c8205792d
az account show --query '{subscription:name, subscriptionId:id, tenantId:tenantId}' --output table
./scripts/Test-Prerequisites.ps1
```

Do not continue if the displayed subscription or tenant is different.

## 2. Verify the Web App and managed identity

The deployed application uses `DefaultAzureCredential`. In App Service that means the Web App's system-assigned managed identity, not the account used by `az login`.

```powershell
$resourceGroup = 'SmartApp'
$webApp = 'web-smartapp-f59ee617'
$identity = az webapp identity show --resource-group $resourceGroup --name $webApp --output json | ConvertFrom-Json
$identity | Select-Object principalId, tenantId, type
```

The expected principal ID is `41f3cdfc-208c-4f4a-8660-34eb21aa9390`. If `principalId` is empty or different, stop and ask the Azure owner to enable or verify the Web App's system-assigned identity. Do not grant roles to your interactive Azure CLI account as a substitute.

Ask the Azure owner to verify these assignments for that exact principal:

| Existing resource | Required role |
|---|---|
| Storage account `stsmartappf59ee617` | Storage Blob Data Contributor |
| Search service `srch-smartapp-f59ee617` | Search Service Contributor and Search Index Data Contributor |
| Azure OpenAI `aoai-smartapp-f59ee617` | Cognitive Services OpenAI User |
| Document Intelligence `docint-smartapp-f59ee617` | Cognitive Services User |
| Key Vault `kv-smartapp-f59ee617` | Key Vault Secrets User |

The storage assignment must be at the storage account, the `knowledge-documents` container, or an inherited scope. Roles such as `Contributor` and `Storage Account Contributor` do not provide Blob data access. Allow time for role propagation and restart the Web App after assignments change.

Use the repository's read-only diagnostic after the owner confirms RBAC:

```powershell
./scripts/Test-AzureAccess.ps1
```

The script separately labels checks made as the Azure CLI user; those checks do not prove that the Web App identity has access.

## 3. Configure App Service settings

Resolve the two service endpoints and configure only non-secret application settings. The command updates the existing Web App; it does not put credentials in the repository.

```powershell
$aoaiEndpoint = az cognitiveservices account show --resource-group $resourceGroup --name aoai-smartapp-f59ee617 --query properties.endpoint --output tsv
$documentEndpoint = az cognitiveservices account show --resource-group $resourceGroup --name docint-smartapp-f59ee617 --query properties.endpoint --output tsv

az webapp config appsettings set --resource-group $resourceGroup --name $webApp --settings `
  ASPNETCORE_ENVIRONMENT=Production `
  SmartAssist__AzureOpenAI__Endpoint=$aoaiEndpoint `
  SmartAssist__AzureOpenAI__ChatDeployment=smartassist-chat `
  SmartAssist__AzureOpenAI__EmbeddingDeployment=smartassist-embedding `
  SmartAssist__Search__Endpoint=https://srch-smartapp-f59ee617.search.windows.net `
  SmartAssist__Search__IndexName=smartassist-knowledge-index `
  SmartAssist__Storage__AccountName=stsmartappf59ee617 `
  SmartAssist__Storage__ContainerName=knowledge-documents `
  SmartAssist__DocumentIntelligence__Endpoint=$documentEndpoint `
  SmartAssist__KeyVault__Uri=https://kv-smartapp-f59ee617.vault.azure.net/
```

Configure `APPLICATIONINSIGHTS_CONNECTION_STRING` directly in the App Service Configuration blade using the existing Application Insights resource. Treat it as sensitive: do not paste it into source files, terminal transcripts, tickets, or chat.

Confirm that the required setting names are present without printing sensitive values:

```powershell
$required = @(
  'ASPNETCORE_ENVIRONMENT',
  'SmartAssist__AzureOpenAI__Endpoint',
  'SmartAssist__AzureOpenAI__ChatDeployment',
  'SmartAssist__AzureOpenAI__EmbeddingDeployment',
  'SmartAssist__Search__Endpoint',
  'SmartAssist__Search__IndexName',
  'SmartAssist__Storage__AccountName',
  'SmartAssist__Storage__ContainerName',
  'SmartAssist__DocumentIntelligence__Endpoint',
  'SmartAssist__KeyVault__Uri'
)
$configuredNames = az webapp config appsettings list --resource-group $resourceGroup --name $webApp --query '[].name' --output tsv
$required | ForEach-Object { if ($_ -notin $configuredNames) { Write-Warning "Missing setting: $_" } else { Write-Host "Present: $_" } }
```

## 4. Configure App Service Authentication

Production authentication intentionally fails closed. In the Azure portal:

1. Open **App Services** > `web-smartapp-f59ee617` > **Authentication**.
2. Add or edit the **Microsoft** identity provider.
3. Select the existing Microsoft Entra application registration approved for this application. If none exists, the Entra owner must create and approve one.
4. Configure the redirect URI as `https://web-smartapp-f59ee617.azurewebsites.net/.auth/login/aad/callback`.
5. Require authentication for all requests and return HTTP `401` for unauthenticated API requests, or redirect browser requests to Microsoft sign-in according to the organization's policy.
6. Define/assign the application roles `Employee` and `KnowledgeAdministrator`, or configure the approved group-to-role mapping.
7. Confirm that App Service forwards the authenticated principal ID, name, and role values. The application consumes the `X-MS-CLIENT-PRINCIPAL-ID`, `X-MS-CLIENT-PRINCIPAL-NAME`, and `X-MS-CLIENT-PRINCIPAL-ROLE` headers supplied by the trusted App Service authentication layer.

Do not enable anonymous production access merely to bypass a `401` or `403`. A signed-in user without either application role will correctly receive `403`.

## 5. Restore, build, test, publish, and deploy

The deployment script performs restore, Release build, all tests, publish, ZIP creation, and deployment to the existing Web App. Deployment is opt-in:

```powershell
git status --short
./scripts/Deploy-WebApp.ps1 -ConfirmDeployment
```

Alternatively, inspect and execute the stages manually:

```powershell
dotnet restore CGSmartK.sln
dotnet build CGSmartK.sln --configuration Release --no-restore
dotnet test CGSmartK.sln --configuration Release --no-build --no-restore
dotnet publish src/CGSmartK.Web/CGSmartK.Web.csproj --configuration Release --no-build --output artifacts/publish
Compress-Archive -Path artifacts/publish/* -DestinationPath artifacts/smartassist.zip -Force
az webapp deploy --resource-group $resourceGroup --name $webApp --src-path artifacts/smartassist.zip --type zip
```

Never deploy when restore, build, or tests fail.

## 6. Restart and validate

```powershell
az webapp restart --resource-group $resourceGroup --name $webApp
az webapp show --resource-group $resourceGroup --name $webApp --query defaultHostName --output tsv
```

Then validate in this order:

1. Open `https://web-smartapp-f59ee617.azurewebsites.net/health/live`; it should return a successful status.
2. Open the application root in a private browser window and complete Microsoft sign-in.
3. Verify an `Employee` can open the assistant but cannot open `/Knowledge`.
4. Verify a `KnowledgeAdministrator` can open `/Knowledge`.
5. Upload only the supplied synthetic test PDF, wait for **Indexed**, and ask a question grounded in it.

If Blob Storage still returns `AuthorizationPermissionMismatch`, capture the failing route and the first application stack frame, rerun `Test-AzureAccess.ps1`, and verify that **Storage Blob Data Contributor** is assigned to the Web App principal—not the deployment user. Do not add an account key or connection string. If authentication returns `401` or `403`, inspect App Service Authentication and application-role assignment before changing application authorization.

## 7. Rollback

Redeploy a previously tested ZIP package or previous application commit. Do not roll back by deleting the storage container, search index, or any other Azure resource.
