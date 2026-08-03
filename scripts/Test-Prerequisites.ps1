# Verifies local tools, login, subscription, and read-only resource visibility. Never requests keys.
[CmdletBinding()]param()
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
function Invoke-Native([scriptblock]$Command){& $Command;$code=$LASTEXITCODE;if($code -ne 0){throw "Native command failed with exit code $code."}}
if($PSVersionTable.PSVersion.Major -lt 7){throw 'PowerShell 7 or newer is required.'}
Invoke-Native { dotnet --version };Invoke-Native { az version --output none };Invoke-Native { az account show --output none }
Invoke-Native { az account set --subscription 'bae405f7-48fe-48ae-a393-b10c8205792d' }
$resources=@('stsmartappf59ee617','kv-smartapp-f59ee617','srch-smartapp-f59ee617','aoai-smartapp-f59ee617','docint-smartapp-f59ee617','appi-smartapp-f59ee617','asp-smartapp-f59ee617','web-smartapp-f59ee617')
foreach($name in $resources){Invoke-Native { az resource list --resource-group SmartApp --name $name --query '[0].name' --output tsv }}
Write-Host 'Prerequisites and resource visibility verified.'
