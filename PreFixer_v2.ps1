<#
.SYNOPSIS
Removes the leading digits before the first "[" in folder names.
Example: 20250923070923[1-1]_Model5  ->  [1-1]_Model5
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Position=0)]
    [string]$Path,          # Optional. If omitted, you'll be prompted.
    [switch]$Recurse        # Optional. Include subfolders.
)

if (-not $Path) {
    $Path = Read-Host "Enter the folder path (e.g. E:\Images\09102025-09172025\1-1)"
}

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Error "Path not found: $Path"
    exit 1
}

$enum = @{ Path = $Path; Directory = $true }
if ($Recurse) { $enum.Recurse = $true }

Get-ChildItem @enum | ForEach-Object {
    $name = $_.Name
    # Only rename if the name STARTS with digits immediately followed by "["
    if ($name -match '^\d+(?=\[)') {
        $newName = $name -replace '^\d+(?=\[)', ''
        if ($PSCmdlet.ShouldProcess($_.FullName, "Rename to '$newName'")) {
            try {
                Rename-Item -LiteralPath $_.FullName -NewName $newName -ErrorAction Stop
                Write-Host "Renamed '$name' -> '$newName'"
            }
            catch {
                Write-Warning "Skipped '$name': $($_.Exception.Message)"
            }
        }
    }
}
