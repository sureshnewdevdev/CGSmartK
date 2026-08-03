<#
.SYNOPSIS
Creates a SmartAssist appsettings.json template.

.DESCRIPTION
Writes a configuration template containing safe placeholders and the default
SmartAssist ingestion, retrieval, MCP, and logging settings. The script does
not add credentials or other secrets to the generated file.

.PARAMETER OutputPath
The path of the JSON file to create. The default is appsettings.json in the
current directory.

.PARAMETER Force
Overwrites the output file when it already exists.

.EXAMPLE
./samples/New-SmartAssistAppSettings.ps1

.EXAMPLE
./samples/New-SmartAssistAppSettings.ps1 -OutputPath ./src/CGSmartK.Web/appsettings.Local.json -Force
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = (Join-Path (Get-Location) 'appsettings.json'),

    [Parameter()]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
            Endpoint = 'https://YOUR-AZURE-OPENAI-RESOURCE.openai.azure.com/'
            ChatDeployment = 'YOUR-CHAT-DEPLOYMENT'
            EmbeddingDeployment = 'YOUR-EMBEDDING-DEPLOYMENT'
            EmbeddingDimensions = 1536
        }
        Search = [ordered]@{
            Endpoint = 'https://YOUR-SEARCH-SERVICE.search.windows.net'
            IndexName = 'YOUR-SEARCH-INDEX'
        }
        Storage = [ordered]@{
            AccountName = 'yourstorageaccount'
            ContainerName = 'your-container'
        }
        DocumentIntelligence = [ordered]@{
            Endpoint = 'https://YOUR-DOCUMENT-INTELLIGENCE-RESOURCE.cognitiveservices.azure.com/'
        }
        KeyVault = [ordered]@{
            Uri = 'https://YOUR-KEY-VAULT.vault.azure.net/'
        }
        Ingestion = [ordered]@{
            TargetTokens = 800
            OverlapTokens = 120
            MaxPdfBytes = 20971520
            QueueCapacity = 20
            BatchSize = 50
        }
        Retrieval = [ordered]@{
            TopK = 8
            MinimumScore = 0.55
            MaxPerDocument = 3
        }
        Mcp = [ordered]@{
            Enabled = $false
            Endpoint = $null
            AllowedTools = @()
            TimeoutSeconds = 5
            SyntheticDemo = $false
        }
    }
    Logging = [ordered]@{
        LogLevel = [ordered]@{
            Default = 'Information'
            'Microsoft.AspNetCore' = 'Warning'
            'Azure.Core' = 'Warning'
        }
    }
    AllowedHosts = '*'
}

$json = $settings | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($resolvedOutputPath, "$json$([Environment]::NewLine)", [System.Text.UTF8Encoding]::new($false))

Write-Host "Created SmartAssist settings template: $resolvedOutputPath"
