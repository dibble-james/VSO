function Find-InstallLocation($stepName) {
    $result = $OctopusParameters.Keys | where {
        $_.Equals("Octopus.Action[$stepName].Output.Package.InstallationDirectoryPath",  [System.StringComparison]::OrdinalIgnoreCase)
    } | select -first 1
 
    if ($result) {
        return $OctopusParameters[$result]
    }
 
    throw "No install location found for step: $stepName"
}
 
function Find-SingleInstallLocation {
    $all = @(Find-InstallLocations)
    if ($all.Length -eq 1) {
        return $all[0]
    }
    if ($all.Length -eq 0) {
        throw "No package steps found"
    }
    throw "Multiple package steps have run; please specify a single step"
}

$DeployedPackage = $OctopusParameters['DeployedPackage']

$stepPath = ""
if (-not [string]::IsNullOrEmpty($DeployedPackage)) {
    Write-Host "Finding path to package step: $DeployedPackage"
    $stepPath = Find-InstallLocation $DeployedPackage
} else {
    $stepPath = Find-SingleInstallLocation
}
Write-Host "Package was installed to: $stepPath"

$version = $OctopusParameters['Version'].Replace('.', '_');

$deploymentManifest = $stepPath + "\" + $OctopusParameters['DeploymentManifest']

$applicationManifest = $stepPath + "\Application Files\" + $OctopusParameters['VersionPrefix'] + "_" + $version + "\" + $OctopusParameters['ApplicationManifest']

$providerURL = $OctopusParameters['NewProviderURL'] + "/" + $OctopusParameters['DeploymentManifest']

$certFile = $stepPath + "\" + $OctopusParameters['Cert']

$certPass = $OctopusParameters['CertPass']

$mage = $OctopusParameters['Mage']

Write-Host "Updating $deploymentManifest and $applicationManifest with $providerURL"

Write-Host "& $mage -Update $deploymentManifest -ProviderURL $providerURL -AppManifest $applicationManifest -CertFile $certFile -Password $certPass"

& $mage -Update "$deploymentManifest" -ProviderURL "$providerURL" -AppManifest "$applicationManifest" -CertFile "$certFile" -Password "$certPass"