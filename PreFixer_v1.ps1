<#
.SYNOPSIS
Removes leading digits before the first "[" in folder names.
Loops until the user types 'quit' or 'q'.

Example: 20250923070923[1-1]_Model5  ->  [1-1]_Model5
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Position=0)]
    [string]$Path,         # Optional: if provided, processes once, then enters loop.
    [switch]$Recurse       # Optional default for the first run (you can change per-loop).
)

function Invoke-RenameForPath {
    param(
        [Parameter(Mandatory)]
        [string]$TargetPath,
        [bool]$DoRecurse
    )

    if (-not (Test-Path -LiteralPath $TargetPath)) {
        Write-Error "Path not found: $TargetPath"
        return
    }

    $enum = @{ Path = $TargetPath; Directory = $true }
    if ($DoRecurse) { $enum.Recurse = $true }

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
}

# --- First run if -Path was passed ---
if ($PSBoundParameters.ContainsKey('Path')) {
    Invoke-RenameForPath -TargetPath $Path -DoRecurse:[bool]$Recurse
}

# --- Interactive loop ---
while ($true) {
    $inputPath = Read-Host 'Enter the folder path (or type "quit" to exit)'
    if ($inputPath -match '^(?i:q(uit)?)$') { break }

    # Ask recursion each time (Y/N). Default = N if blank.
    $recAns = Read-Host 'Recurse into subfolders? (Y/N, default N)'
    $doRecurse = $false
    if ($recAns -match '^(?i:y(es)?)$') { $doRecurse = $true }

    Invoke-RenameForPath -TargetPath $inputPath -DoRecurse:$doRecurse

    # Optional: small separator
    Write-Host ('-' * 50)
}

Write-Host "Done."
