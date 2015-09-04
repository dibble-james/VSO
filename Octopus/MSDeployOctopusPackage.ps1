# A collection of functions that can be used by script steps to determine where packages installed
# by previous steps are located on the filesystem.
 
function Find-InstallLocations {
    $result = @()
    $OctopusParameters.Keys | foreach {
        if ($_.EndsWith('].Output.Package.InstallationDirectoryPath')) {
            $result += $OctopusParameters[$_]
        }
    }
    return $result
}
 
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

function Test-LastExit($cmd) {
    if ($LastExitCode -ne 0) {
        Write-Host "##octopus[stderr-error]"
        write-error "$cmd failed with exit code: $LastExitCode"
    }
}

$WebDeployPackage = $OctopusParameters['WebDeployPackage']
$Destination = $OctopusParameters['Destination']
$VirtualDirectory = $OctopusParameters['VirtualDirectory']
$WebDeployUser = $OctopusParameters['WebDeployUser']
$WebDeployPassword = $OctopusParameters['WebDeployPassword']
$AgentType = $OctopusParameters['AgentType']
$AllowUntrusted = $OctopusParameters['AllowUntrusted'] -eq 'True'

$stepName = $OctopusParameters['WebDeployPackageStepName']

$stepPath = ""
if (-not [string]::IsNullOrEmpty($stepName)) {
    Write-Host "Finding path to package step: $stepName"
    $stepPath = Find-InstallLocation $stepName
} else {
    $stepPath = Find-SingleInstallLocation
}

Write-Host "Package was installed to: $stepPath"

$WebDeployPackage = "$stepPath/$WebDeployPackage"

Write-Host -Foreground Green "Deploying $WebDeployPackage"

Add-PSSnapin WDeploySnapin3.0

$deploymentParameters = Get-WDParameters $WebDeployPackage

$overridenParameters = convertfrom-stringdata -stringdata $OctopusParameters['PackageParameters']

$mergedDeploymentParameters = @{};

ForEach($deploymentParameter in $deploymentParameters.GetEnumerator())
{
    $parameterName = $deploymentParameter.Name -replace "[^a-zA-Z0-9]", ""
    $parameterNameUpper = $parameterName.ToUpper()

    # Default the parameter value to the default value in SetParameters.xml
    $parameterValue = $deploymentParameter.Value

    # Explicit deployment parameter trumps all
    if($overridenParameters.ContainsKey($parameterName))
    {
        $parameterValue = $overridenParameters[$parameterName]
    }
    
    $mergedDeploymentParameters[$deploymentParameter.Name] = $parameterValue
}

$mergedDeploymentParameters['IIS Web Application Name'] = $VirtualDirectory

$packageParametersVerbose = ($mergedDeploymentParameters | Out-String)

Write-Verbose "Package Parameters $packageParametersVerbose" 

try
{
    Write-Host -Foreground Green "Deploying to $destination/$VirtualDirectory"

    $settingsFilename = "$WebDeployPackage.$destination.publishsettings"

    New-WDPublishSettings -AllowUntrusted:$AllowUntrusted -EncryptPassword -ComputerName $destination -UserId $WebDeployUser -Password $WebDeployPassword -FileName "$settingsFilename" -AgentType $AgentType -Site $VirtualDirectory

    Write-Verbose "Using $settingsFilename"

    Restore-WDPackage -Package $WebDeployPackage -Verbose -DestinationPublishSettings $settingsFilename -ErrorAction Stop -Parameters $mergedDeploymentParameters

    Write-Host -Foreground Green "Sucessfully Deployed to $destination"
}
catch
{
    Write-Host -Foreground Red "Failed to deploy to $destination`n$_"

    Exit 1
}