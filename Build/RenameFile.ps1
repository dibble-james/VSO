[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $Location,
    [Parameter(Mandatory)][string] $NewName
)

Rename-Item $Location $NewName