[CmdletBinding()]
param(
    [Parameter(Mandatory, Position=1)][string] $NewLocation,
    [Parameter(Position=2)][string[]] $FileMatches 
)

foreach($match in $FileMatches)
{
    Write-Host "`nCopying files that match the REGEX pattern [$match] to [$NewLocation]`n"

    $files = Get-ChildItem -Recurse | Where-Object { $_.Name -match "$match" }

    foreach($file in $files)
    {
        Write-Host $file

        Copy-Item $file $NewLocation
    }
}