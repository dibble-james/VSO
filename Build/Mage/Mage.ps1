[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $Manifest,
    [Parameter(Mandatory)][string] $AppManifest,
    [Parameter(Mandatory)][string] $NewProviderURL,
    [Parameter(Mandatory)][string] $Cert,
    [Parameter(Mandatory)][string] $CertPass,
    [Parameter()][string] $Mage = "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6 Tools\mage.exe",
    [Parameter()][string] $workingFolder
)

$deploymentManifest = (Get-ChildItem -Filter $Manifest -Recurse).FullName

$applicationManifest = (Get-ChildItem -Filter $AppManifest -Recurse).FullName

$providerURL = $NewProviderURL + "/" + $Manifest

Write-Host "Updating $deploymentManifest and $applicationManifest with $providerURL"

Write-Host "& $mage -Update $deploymentManifest -ProviderURL $providerURL -AppManifest $applicationManifest -CertFile $certFile -Password $certPass"

& $mage -Update "$deploymentManifest" -ProviderURL "$providerURL" -AppManifest "$applicationManifest" -CertFile "$Cert" -Password "$CertPass"