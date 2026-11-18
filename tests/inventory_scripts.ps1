# Mutation tests use a temporary example checkout only; no lab connectivity.
$ErrorActionPreference = 'Stop'
Import-Module powershell-yaml
$source = Split-Path -Parent $PSScriptRoot
$temporary = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporary | Out-Null
try {
    foreach ($folder in @('scripts','inventory','.github')) {
        Copy-Item -LiteralPath (Join-Path $source $folder) -Destination $temporary -Recurse
    }
    $inventoryPath = Join-Path $temporary 'inventory/hosts.yml'
    $updater = Join-Path $temporary 'scripts/Update-Inventory.ps1'
    $groupCreator = Join-Path $temporary 'scripts/New-AnsibleGroup.ps1'
    & $updater -VmName 'test-node' -IpAddress '192.0.2.200' -Group 'docker'
    $data = ConvertFrom-Yaml (Get-Content $inventoryPath -Raw)
    if (-not $data.all.children.linux_hosts.children.docker.hosts.Contains('test-node')) { throw 'Nested group update failed.' }
    if ($data.all.children.network_devices.children.opnsense.hosts.Contains('test-node')) { throw 'Network device group changed.' }
    $hostPath = Join-Path $temporary 'inventory/host_vars/test-node.yml'
    $vars = ConvertFrom-Yaml (Get-Content $hostPath -Raw)
    $vars['custom_example'] = 'preserve-me'
    $vars | ConvertTo-Yaml | Set-Content $hostPath
    & $updater -VmName 'test-node' -IpAddress '192.0.2.201' -Group 'docker'
    $vars = ConvertFrom-Yaml (Get-Content $hostPath -Raw)
    if ($vars.ansible_host -ne '192.0.2.201' -or $vars.custom_example -ne 'preserve-me') { throw 'Host variables were not preserved.' }
    $before = Get-Content $inventoryPath -Raw
    & $updater -VmName 'test-node' -IpAddress '192.0.2.201' -Group 'docker'
    if ((Get-Content $inventoryPath -Raw) -ne $before) { throw 'Inventory mutation was not idempotent.' }
    foreach ($invalid in @('999.1.1.1','192.0.02.1','::1')) {
        $failed = $false
        try { & $updater -VmName 'bad-node' -IpAddress $invalid -Group 'docker' } catch { $failed = $true }
        if (-not $failed) { throw 'Invalid address was accepted.' }
    }
    $failed = $false
    try { & $updater -VmName 'bad-node' -IpAddress '192.0.2.202' -Group 'unknown-group' } catch { $failed = $true }
    if (-not $failed) { throw 'Unknown group was accepted.' }
    & $groupCreator -GroupName 'example-services'
    & $groupCreator -GroupName 'example-services'
    & $updater -VmName 'new-node' -IpAddress '192.0.2.203' -Group 'example-services'
    $data = ConvertFrom-Yaml (Get-Content $inventoryPath -Raw)
    if (-not $data.all.children.linux_hosts.children.'example-services'.hosts.Contains('new-node')) { throw 'New group membership failed.' }
    $workflow = ConvertFrom-Yaml (Get-Content (Join-Path $temporary '.github/workflows/create-new-vm.yml') -Raw)
    if (@($workflow.on.workflow_dispatch.inputs.group.options | Where-Object { $_ -eq 'example-services' }).Count -ne 1) { throw 'Workflow group menu is not synchronized.' }
    Write-Host 'PASS: nested inventory, variable preservation, idempotence, invalid inputs, group creation, and workflow menu.'
}
finally { Remove-Item -LiteralPath $temporary -Recurse -Force }
