# Writes safe endpoints and identifiers to .NET user-secrets. It never reads or stores access keys/tokens.
[CmdletBinding()]param()
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop';$subscription='bae405f7-48fe-48ae-a393-b10c8205792d';$tenant='b24388d9-c6ca-4c64-a601-5edb6e666e1e';$project='src/CGSmartK.Web/CGSmartK.Web.csproj'
az account set --subscription $subscription;if($LASTEXITCODE -ne 0){throw 'Select the subscription after az login --tenant $tenant.'}
$aoai=az cognitiveservices account show -g SmartApp -n aoai-smartapp-f59ee617 --query properties.endpoint -o tsv;if($LASTEXITCODE -ne 0){throw 'Cannot read the Azure OpenAI endpoint.'}
$doc=az cognitiveservices account show -g SmartApp -n docint-smartapp-f59ee617 --query properties.endpoint -o tsv;if($LASTEXITCODE -ne 0){throw 'Cannot read the Document Intelligence endpoint.'}
$values=@{'SmartAssist:AzureOpenAI:Endpoint'=$aoai;'SmartAssist:DocumentIntelligence:Endpoint'=$doc;'SmartAssist:Search:Endpoint'='https://srch-smartapp-f59ee617.search.windows.net';'SmartAssist:Search:IndexName'='smartassist-knowledge-index';'SmartAssist:Storage:AccountName'='stsmartappf59ee617';'SmartAssist:Storage:ContainerName'='knowledge-documents';'SmartAssist:KeyVault:Uri'='https://kv-smartapp-f59ee617.vault.azure.net/'}
foreach($entry in $values.GetEnumerator()){dotnet user-secrets set $entry.Key $entry.Value --project $project;if($LASTEXITCODE -ne 0){throw "Could not set $($entry.Key)."}}
Write-Host 'Safe local settings configured. Values were not printed.'
