[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $WebDeployPackage,
    [Parameter(Mandatory)][string] $PackageDestinations,
    [Parameter(Mandatory)][string] $VirtualDirectory,
    [Parameter()][string] $PackageParameters,
    [Parameter()][string] $AgentType = "MSDepSvc",
    [Parameter()][string] $AllowUntrusted,
    [Parameter()][string] $MergeBuildVariables
)

import-module "Microsoft.TeamFoundation.DistributedTask.Task.Internal" 
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Common" 
import-module "Microsoft.TeamFoundation.DistributedTask.Task.DevTestLabs" 
Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Deployment.Internal" 

Write-Host -Foreground Green "Deploying $WebDeployPackage"
Write-Verbose "PackageDestinations = $PackageDestinations" -Verbose
Write-Verbose "AllowUntrusted = $AllowUntrusted" -Verbose
Write-Verbose "MergeBuildVariables = $MergeBuildVariables" -Verbose

Add-PSSnapin WDeploySnapin3.0

$resourceFQDNKeyName = Get-ResourceFQDNTagKey

$skipCaCheck = $AllowUntrusted -eq "true"
$useEnvironmentVariables = $MergeBuildVariables -eq "true"

$deploymentParameters = Get-WDParameters $WebDeployPackage

$environmentVariables = Get-ChildItem Env:

$environmentVariablesVerbose = ($environmentVariables | Out-String)

Write-Verbose "Environment Variables Parameters $environmentVariablesVerbose" 

$mergedDeploymentParameters = @{};

ForEach($deploymentParameter in $deploymentParameters.GetEnumerator())
{
    $parameterName = $deploymentParameter.Name -replace "[^a-zA-Z0-9]", ""
    $parameterNameUpper = $parameterName.ToUpper()

    # Default the parameter value to the default value in SetParameters.xml
    $parameterValue = $deploymentParameter.Value

    # Try getting the parameter from environment variables 
    if($useEnvironmentVariables -and (Test-Path Env:$parameterNameUpper))
    {
        $parameterValue = (Get-Item Env:$parameterNameUpper).Value
    }

    $mergedDeploymentParameters[$deploymentParameter.Name] = $parameterValue
}

function Get-ResourceConnectionDetails
{
    param([object]$resource)

    $resourceProperties = @{}
    $resourceName = $resource.Name
    $resourceId = $resource.Id

    Write-Verbose "Starting Get-EnvironmentProperty cmdlet call on environment name: $PackageDestinations with resource id: $resourceId(Name : $resourceName) and key: $resourceFQDNKeyName" -Verbose
    $fqdn = Get-EnvironmentProperty -EnvironmentName $PackageDestinations -Key $resourceFQDNKeyName -Connection $connection -ResourceId $resourceId -TaskContext $distributedTaskContext
    Write-Verbose "Completed Get-EnvironmentProperty cmdlet call on environment name: $PackageDestinations with resource id: $resourceId(Name : $resourceName) and key: $resourceFQDNKeyName" -Verbose

    $resourceProperties.fqdn = $fqdn
    $resourceProperties.credential = Get-ResourceCredentials -resource $resource    
    $resourceProperties.displayName = $fqdn

    return $resourceProperties
}

function Get-ResourcesProperties
{
    param([object]$resources)

    [hashtable]$resourcesPropertyBag = @{}

    foreach ($resource in $resources)
    {
        $resourceName = $resource.Name
        $resourceId = $resource.Id
        Write-Verbose "Get Resource properties for $resourceName (ResourceId = $resourceId)" -Verbose
        $resourceProperties = Get-ResourceConnectionDetails -resource $resource
        $resourceProperties.skipCACheckOption = $skipCACheckOption
        $resourcesPropertyBag.add($resourceId, $resourceProperties)
    }

    return $resourcesPropertyBag
}

$mergedDeploymentParameters['IIS Web Application Name'] = $VirtualDirectory

$packageParametersVerbose = ($mergedDeploymentParameters | Out-String)

Write-Verbose "Package Parameters $packageParametersVerbose" 
$connection = Get-VssConnection -TaskContext $distributedTaskContext

# This is temporary fix for filtering 
Write-Verbose "Starting Register-Environment cmdlet call for environment : $PackageDestinations" -Verbose
$environment = Register-Environment -EnvironmentName $PackageDestinations -EnvironmentSpecification $PackageDestinations -Connection $connection -TaskContext $distributedTaskContext
Write-Verbose "Completed Register-Environment cmdlet call for environment : $PackageDestinations" -Verbose

Write-Verbose "Starting Get-EnvironmentResources cmdlet call on environment name: $PackageDestinations" -Verbose
$resources = Get-EnvironmentResources -EnvironmentName $PackageDestinations -TaskContext $distributedTaskContext
Write-Verbose "Completed Get-EnvironmentResources cmdlet call on environment name: $PackageDestinations" -Verbose

if ($resources.Count -eq 0)
{
  throw "No machine exists under environment: '$PackageDestinations' for deployment"
}

$resourcesPropertyBag = Get-ResourcesProperties -resources $resources

foreach($resource in $resources)
{
    $resourceProperties = $resourcesPropertyBag.Item($resource.Id)
    $machine = $resourceProperties.fqdn
    $displayName = $resourceProperties.displayName
    Write-Output (Get-LocalizedString -Key "Deployment started for machine: '{0}'" -ArgumentList $displayName)

    try
    {
        Write-Host -Foreground Green "Deploying to $machine/$VirtualDirectory using $AgentType"

        $settingsFilename = "$WebDeployPackage.$machine.publishsettings"

        New-WDPublishSettings -AllowUntrusted:$skipCaCheck -EncryptPassword -ComputerName $machine -UserId $resourceProperties.credential.UserName -Password  $resourceProperties.credential.Password -FileName "$settingsFilename" -AgentType $AgentType -Site $VirtualDirectory

        Write-Verbose "Using $settingsFilename" -Verbose

        Restore-WDPackage -Package $WebDeployPackage -DestinationPublishSettings $settingsFilename -ErrorAction Stop -Parameters $mergedDeploymentParameters 4> Write-Host

        Write-Host -Foreground Green "Sucessfully Deployed to $machine"
    }
    catch
    {
        Write-Host -Foreground Red "Failed to deploy to $machine`n$_"

        Exit 1
    }
}
