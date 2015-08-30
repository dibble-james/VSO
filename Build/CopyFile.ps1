[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $File,
    [Parameter(Mandatory)][string] $NewLocation
)

Copy-Item $File $NewLocation