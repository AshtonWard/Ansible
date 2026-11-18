# Shared helpers for the example inventory's nested group structure.
function Read-InventoryYaml {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "File not found: $Path" }
    $data = ConvertFrom-Yaml -Ordered (Get-Content -LiteralPath $Path -Raw)
    if ($data -isnot [System.Collections.IDictionary]) { throw "Expected a YAML mapping: $Path" }
    return $data
}

function Find-InventoryGroup {
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Inventory,
          [Parameter(Mandatory)][string]$Name)
    $found = [System.Collections.Generic.List[object]]::new()
    function Visit-InventoryGroups {
        param([System.Collections.IDictionary]$Groups)
        foreach ($key in @($Groups.Keys)) {
            if ($null -eq $Groups[$key]) { $Groups[$key] = [ordered]@{} }
            $node = $Groups[$key]
            if ($node -isnot [System.Collections.IDictionary]) { throw "Invalid group mapping: $key" }
            if ($key -eq $Name) { $found.Add($node) }
            if ($node['children']) { Visit-InventoryGroups $node['children'] }
        }
    }
    Visit-InventoryGroups $Inventory
    return $found.ToArray()
}

function Write-InventoryYaml {
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Data,
          [Parameter(Mandatory)][string]$Path)
    $temporary = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        $Data | ConvertTo-Yaml | Set-Content -LiteralPath $temporary -Encoding utf8
        Move-Item -LiteralPath $temporary -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    }
}
