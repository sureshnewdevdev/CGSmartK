# Runs read-only management/data-plane diagnostics and maps common RBAC failures.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$subscription = 'bae405f7-48fe-48ae-a393-b10c8205792d'
$resourceGroup = 'SmartApp'
$webApp = 'web-smartapp-f59ee617'
$storageAccount = 'stsmartappf59ee617'
$container = 'knowledge-documents'
$searchEndpoint = 'https://srch-smartapp-f59ee617.search.windows.net'
$expectedSettings = @(
    'SmartAssist__AzureOpenAI__Endpoint',
    'SmartAssist__AzureOpenAI__ChatDeployment',
    'SmartAssist__AzureOpenAI__EmbeddingDeployment',
    'SmartAssist__Search__Endpoint',
    'SmartAssist__Search__IndexName',
    'SmartAssist__Storage__AccountName',
    'SmartAssist__Storage__ContainerName',
    'SmartAssist__DocumentIntelligence__Endpoint'
)

az account set --subscription $subscription
if ($LASTEXITCODE -ne 0) { throw 'Azure login or subscription selection failed.' }

$identity = az webapp identity show --resource-group $resourceGroup --name $webApp --output json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or -not $identity.principalId) {
    throw 'The Web App system-assigned managed identity is not enabled or could not be inspected.'
}

Write-Host "Web App managed identity: $($identity.principalId)"

$settings = az webapp config appsettings list --resource-group $resourceGroup --name $webApp --output json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect Web App settings.' }

foreach ($name in $expectedSettings) {
    $setting = $settings | Where-Object name -eq $name | Select-Object -First 1
    if ($null -eq $setting -or [string]::IsNullOrWhiteSpace($setting.value)) {
        Write-Warning "App setting is missing or empty: $name"
    }
    else {
        Write-Host "App setting is present: $name"
    }
}

if ($settings.name -contains 'AzureWebJobsStorage' -or $settings.name -contains 'SmartAssist__Storage__ConnectionString') {
    Write-Warning 'A storage connection-string setting is present. The application does not use it; remove it after confirming no platform feature depends on it.'
}
else {
    Write-Host 'Storage authentication: DefaultAzureCredential (no application connection string configured).'
}

$storageId = az storage account show --resource-group $resourceGroup --name $storageAccount --query id --output tsv
$searchId = az search service show --resource-group $resourceGroup --name srch-smartapp-f59ee617 --query id --output tsv
$keyVaultId = az keyvault show --resource-group $resourceGroup --name kv-smartapp-f59ee617 --query id --output tsv
$openAiId = az cognitiveservices account show --resource-group $resourceGroup --name aoai-smartapp-f59ee617 --query id --output tsv
$documentIntelligenceId = az cognitiveservices account show --resource-group $resourceGroup --name docint-smartapp-f59ee617 --query id --output tsv
if ($LASTEXITCODE -ne 0 -or -not $storageId -or -not $searchId -or -not $keyVaultId -or -not $openAiId -or -not $documentIntelligenceId) {
    throw 'Could not resolve the expected Azure resource scopes.'
}

$assignments = az role assignment list --assignee-object-id $identity.principalId --all --output json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect managed-identity role assignments.' }

$requiredRoles = @(
    @{ Name = 'Storage Blob Data Contributor'; Scope = $storageId },
    @{ Name = 'Key Vault Secrets User'; Scope = $keyVaultId },
    @{ Name = 'Search Service Contributor'; Scope = $searchId },
    @{ Name = 'Search Index Data Contributor'; Scope = $searchId },
    @{ Name = 'Cognitive Services OpenAI User'; Scope = $openAiId },
    @{ Name = 'Cognitive Services User'; Scope = $documentIntelligenceId }
)

foreach ($required in $requiredRoles) {
    $match = $assignments | Where-Object {
        $_.roleDefinitionName -eq $required.Name -and
        ($required.Scope.StartsWith($_.scope, [System.StringComparison]::OrdinalIgnoreCase))
    } | Select-Object -First 1

    if ($null -eq $match) {
        Write-Warning "Managed identity is missing '$($required.Name)' at the resource scope or an inherited scope: $($required.Scope)"
    }
    else {
        Write-Host "Managed identity role verified: $($required.Name) ($($match.scope))"
    }
}

# This data-plane call uses the interactive Azure CLI identity. It verifies the
# resource/container and the developer's local access, not the Web App identity.
$blobOutput = az storage blob list --auth-mode login --account-name $storageAccount --container-name $container --num-results 1 --output none 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host 'Blob data plane (current Azure CLI identity): access verified.'
}
elseif ($blobOutput -match '403|AuthorizationPermissionMismatch|Forbidden') {
    Write-Warning 'Blob data plane (current Azure CLI identity): permission denied. This result does not test the Web App identity.'
}
elseif ($blobOutput -match '404|not found') {
    Write-Warning 'Blob data plane: the configured account or container was not found.'
}
else {
    Write-Warning "Blob data plane: service unavailable or provisioning incomplete (exit $LASTEXITCODE)."
}

$searchOutput = az rest --method get --url "$searchEndpoint/indexes?api-version=2024-07-01" --resource 'https://search.azure.com' --output none 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host 'Search data plane (current Azure CLI identity): access verified.'
}
elseif ($searchOutput -match '403|Forbidden') {
    Write-Warning 'Search data plane (current Azure CLI identity): permission denied. This result does not test the Web App identity.'
}
else {
    Write-Warning "Search data plane: service unavailable or provisioning incomplete (exit $LASTEXITCODE)."
}
