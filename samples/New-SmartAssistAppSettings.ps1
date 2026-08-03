<#
.SYNOPSIS
Creates a SmartAssist appsettings.json file from values supplied by the user.

.DESCRIPTION
Accepts the Azure resource endpoints, deployment names, storage identifiers,
and optional tuning values needed by SmartAssist, then writes them as JSON.
The script accepts identifiers only; authentication continues to use
DefaultAzureCredential, so do not pass keys, tokens, or connection strings.

.EXAMPLE
./samples/New-SmartAssistAppSettings.ps1 `
    -AzureOpenAIEndpoint 'https://my-openai.openai.azure.com/' `
    -ChatDeployment 'smartassist-chat' `
    -EmbeddingDeployment 'smartassist-embedding' `
    -SearchEndpoint 'https://my-search.search.windows.net' `
    -SearchIndexName 'smartassist-knowledge-index' `
    -StorageAccountName 'mystorageaccount' `
    -StorageContainerName 'knowledge-documents' `
    -DocumentIntelligenceEndpoint 'https://my-doc-intelligence.cognitiveservices.azure.com/' `
    -KeyVaultUri 'https://my-key-vault.vault.azure.net/' `
    -OutputPath './src/CGSmartK.Web/appsettings.Local.json'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+\.openai\.azure\.com/?$')]
    [string]$AzureOpenAIEndpoint,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ChatDeployment,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$EmbeddingDeployment,

    [Parameter()]
    [ValidateRange(1, 65536)]
    [int]$EmbeddingDimensions = 1536,

    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+\.search\.windows\.net/?$')]
    [string]$SearchEndpoint,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SearchIndexName,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9]{3,24}$')]
    [string]$StorageAccountName,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9](?:[a-z0-9-]{1,61}[a-z0-9])$')]
    [string]$StorageContainerName,

    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+\.cognitiveservices\.azure\.com/?$')]
    [string]$DocumentIntelligenceEndpoint,

    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+\.vault\.azure\.net/?$')]
    [string]$KeyVaultUri,

    [Parameter()]
    [ValidateRange(1, 100000)]
    [int]$TargetTokens = 800,

    [Parameter()]
    [ValidateRange(0, 99999)]
    [int]$OverlapTokens = 120,

    [Parameter()]
    [ValidateRange(1, 2147483647)]
    [int]$MaxPdfBytes = 20971520,

    [Parameter()]
    [ValidateRange(1, 10000)]
    [int]$QueueCapacity = 20,

    [Parameter()]
    [ValidateRange(1, 1000)]
    [int]$BatchSize = 50,

    [Parameter()]
    [ValidateRange(1, 1000)]
    [int]$TopK = 8,

    [Parameter()]
    [ValidateRange(0.0, 1.0)]
    [double]$MinimumScore = 0.55,

    [Parameter()]
    [ValidateRange(1, 1000)]
    [int]$MaxPerDocument = 3,

    [Parameter()]
    [switch]$McpEnabled,

    [Parameter()]
    [AllowNull()]
    [string]$McpEndpoint,

    [Parameter()]
    [string[]]$McpAllowedTools = @(),

    [Parameter()]
    [ValidateRange(1, 300)]
    [int]$McpTimeoutSeconds = 5,

    [Parameter()]
    [switch]$McpSyntheticDemo,

    [Parameter()]
    [ValidateSet('Trace', 'Debug', 'Information', 'Warning', 'Error', 'Critical', 'None')]
    [string]$DefaultLogLevel = 'Information',

    [Parameter()]
    [ValidateSet('Trace', 'Debug', 'Information', 'Warning', 'Error', 'Critical', 'None')]
    [string]$AspNetCoreLogLevel = 'Warning',

    [Parameter()]
    [ValidateSet('Trace', 'Debug', 'Information', 'Warning', 'Error', 'Critical', 'None')]
    [string]$AzureCoreLogLevel = 'Warning',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AllowedHosts = '*',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = (Join-Path (Get-Location) 'appsettings.json'),

    [Parameter()]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($OverlapTokens -ge $TargetTokens) {
    throw 'OverlapTokens must be less than TargetTokens.'
}

if ($McpEnabled -and [string]::IsNullOrWhiteSpace($McpEndpoint)) {
    throw 'McpEndpoint is required when McpEnabled is specified.'
}

$resolvedOutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
$outputDirectory = Split-Path -Parent $resolvedOutputPath

if (Test-Path -LiteralPath $resolvedOutputPath -PathType Container) {
    throw "OutputPath must identify a file: $resolvedOutputPath"
}

if ((Test-Path -LiteralPath $resolvedOutputPath) -and -not $Force) {
    throw "The output file already exists. Use -Force to overwrite it: $resolvedOutputPath"
}

if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$settings = [ordered]@{
    SmartAssist = [ordered]@{
        AzureOpenAI = [ordered]@{
            Endpoint = $AzureOpenAIEndpoint
            ChatDeployment = $ChatDeployment
            EmbeddingDeployment = $EmbeddingDeployment
            EmbeddingDimensions = $EmbeddingDimensions
        }
        Search = [ordered]@{
            Endpoint = $SearchEndpoint
            IndexName = $SearchIndexName
        }
        Storage = [ordered]@{
            AccountName = $StorageAccountName
            ContainerName = $StorageContainerName
        }
        DocumentIntelligence = [ordered]@{
            Endpoint = $DocumentIntelligenceEndpoint
        }
        KeyVault = [ordered]@{
            Uri = $KeyVaultUri
        }
        Ingestion = [ordered]@{
            TargetTokens = $TargetTokens
            OverlapTokens = $OverlapTokens
            MaxPdfBytes = $MaxPdfBytes
            QueueCapacity = $QueueCapacity
            BatchSize = $BatchSize
        }
        Retrieval = [ordered]@{
            TopK = $TopK
            MinimumScore = $MinimumScore
            MaxPerDocument = $MaxPerDocument
        }
        Mcp = [ordered]@{
            Enabled = [bool]$McpEnabled
            Endpoint = if ([string]::IsNullOrWhiteSpace($McpEndpoint)) { $null } else { $McpEndpoint }
            AllowedTools = @($McpAllowedTools)
            TimeoutSeconds = $McpTimeoutSeconds
            SyntheticDemo = [bool]$McpSyntheticDemo
        }
    }
    Logging = [ordered]@{
        LogLevel = [ordered]@{
            Default = $DefaultLogLevel
            'Microsoft.AspNetCore' = $AspNetCoreLogLevel
            'Azure.Core' = $AzureCoreLogLevel
        }
    }
    AllowedHosts = $AllowedHosts
}

$json = $settings | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($resolvedOutputPath, "$json$([Environment]::NewLine)", [System.Text.UTF8Encoding]::new($false))

Write-Host "Created SmartAssist settings file: $resolvedOutputPath"
