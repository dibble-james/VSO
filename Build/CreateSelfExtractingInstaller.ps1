[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $ConfigLocation,
    [Parameter(Mandatory)][string] $DirectoryToPackage,
    [Parameter(Mandatory)][string] $InstallerName,
    [Parameter(Mandatory)][string] $PfxLocation,
    [Parameter(Mandatory)][string] $PfxPassword
)

choco install winrar -y

$startLocation = Get-Location

Set-Location $DirectoryToPackage

$configFile = $startLocation.ToString() + "/$ConfigLocation"

$outputLocation = Join-Path $startLocation.ToString() $InstallerName

rar a -sfx -r -z"$configFile" $outputLocation

Set-Location $startLocation

signtool sign /f $PfxLocation /p $PfxPassword /d "$InstallerName" "$InstallerName"