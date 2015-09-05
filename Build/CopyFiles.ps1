[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $NewLocation,
    [Parameter(Position=1)][string[]] $FileMatches 
)

foreach($match in $FileMatches)
{
    Write-Host "`nCopying files that match the REGEX pattern $match`n"

    $files = Get-ChildItem -Recurse | Where-Object { $_.Name -match "$match" }

    foreach($file in $files)
    {
        Write-Host $file

        Copy-Item $file $NewLocation -Verbose
    }
}