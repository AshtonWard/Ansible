# Add a VM to an existing leaf group, including groups nested below linux_hosts.
param(
    [Parameter(Mandatory)][ValidatePattern('^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$')][string]$VmName,
    [Parameter(Mandatory)][string]$IpAddress,
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9_-]+$')][string]$Group
)
$ErrorActionPreference = 'Stop'
Import-Module powershell-yaml
. (Join-Path $PSScriptRoot 'Inventory-Helpers.ps1')
$parsed = $null
if ($IpAddress -notmatch '^(0|[1-9][0-9]{0,2})(\.(0|[1-9][0-9]{0,2})){3}$' -or
    -not [System.Net.IPAddress]::TryParse($IpAddress, [ref]$parsed) -or
    $parsed.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
    throw 'Expected a valid IPv4 address without leading zeroes.'
}
$root = Split-Path -Parent $PSScriptRoot
$inventoryPath = Join-Path $root 'inventory/hosts.yml'
$inventory = Read-InventoryYaml $inventoryPath
$groups = @(Find-InventoryGroup -Inventory $inventory -Name $Group)
if ($groups.Count -ne 1) { throw 'Group must exist exactly once in inventory.' }
$node = $groups[0]
if ($node['children']) { throw 'Select a leaf group rather than a parent group.' }
if ($null -eq $node['hosts']) { $node['hosts'] = [ordered]@{} }
if ($node['hosts'] -isnot [System.Collections.IDictionary]) { throw 'Expected a hosts mapping.' }
$hostVarsDir = Join-Path $root 'inventory/host_vars'
$hostVarsPath = Join-Path $hostVarsDir "$VmName.yml"
$hostVars = if (Test-Path -LiteralPath $hostVarsPath) { Read-InventoryYaml $hostVarsPath } else { [ordered]@{} }
$hostVars['ansible_host'] = $IpAddress
if (-not $node['hosts'].Contains($VmName)) { $node['hosts'][$VmName] = $null }
if (-not (Test-Path -LiteralPath $hostVarsDir)) { New-Item -ItemType Directory -Path $hostVarsDir | Out-Null }
Write-InventoryYaml -Data $hostVars -Path $hostVarsPath
Write-InventoryYaml -Data $inventory -Path $inventoryPath
Write-Host "Updated inventory membership and host variables for $VmName."
