# Create a nested group and keep the provisioning workflow's menu in sync.
param(
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9_-]+$')][string]$GroupName,
    [ValidatePattern('^[a-zA-Z0-9_-]+$')][string]$ParentGroup = 'linux_hosts'
)
$ErrorActionPreference = 'Stop'
Import-Module powershell-yaml
. (Join-Path $PSScriptRoot 'Inventory-Helpers.ps1')
$root = Split-Path -Parent $PSScriptRoot
$inventoryPath = Join-Path $root 'inventory/hosts.yml'
$inventory = Read-InventoryYaml $inventoryPath
$existing = @(Find-InventoryGroup -Inventory $inventory -Name $GroupName)
if ($existing.Count -gt 1) { throw 'Group name is ambiguous in inventory.' }
if ($existing.Count -eq 0) {
    $parents = @(Find-InventoryGroup -Inventory $inventory -Name $ParentGroup)
    if ($parents.Count -ne 1) { throw 'Parent group must exist exactly once.' }
    $parent = $parents[0]
    if ($null -eq $parent['children']) { $parent['children'] = [ordered]@{} }
    $parent['children'][$GroupName] = [ordered]@{ hosts = [ordered]@{} }
}
$workflowPath = Join-Path $root '.github/workflows/create-new-vm.yml'
$workflow = Read-InventoryYaml $workflowPath
$groupInput = $workflow['on']['workflow_dispatch']['inputs']['group']
if ($null -eq $groupInput) { throw 'Provisioning group input was not found.' }
$groupInput['options'] = @(@($groupInput['options']) + $GroupName | Sort-Object -Unique)
$groupVarsDir = Join-Path $root 'inventory/group_vars'
if (-not (Test-Path -LiteralPath $groupVarsDir)) { New-Item -ItemType Directory -Path $groupVarsDir | Out-Null }
$groupVarsPath = Join-Path $groupVarsDir "$GroupName.yml"
if (-not (Test-Path -LiteralPath $groupVarsPath)) {
    "---`n# Example group variables; keep credentials outside tracked files.`n{}" | Set-Content -LiteralPath $groupVarsPath -Encoding utf8
}
Write-InventoryYaml -Data $inventory -Path $inventoryPath
Write-InventoryYaml -Data $workflow -Path $workflowPath
Write-Host "Synchronized group $GroupName and provisioning menu."
