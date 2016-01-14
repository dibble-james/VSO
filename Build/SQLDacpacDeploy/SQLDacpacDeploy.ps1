[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $Dacpac,
    [Parameter(Mandatory)][string] $PackageDestinations,
    [Parameter(Mandatory)][string] $Database,
    [Parameter()][string] $ResourceFilteringMethod,
    [Parameter()][string] $ResourceFilter,
    [Parameter()][string] $AdditonalParameters
)

# import-module "Microsoft.TeamFoundation.DistributedTask.Task.Internal" 
# import-module "Microsoft.TeamFoundation.DistributedTask.Task.Common" 
# import-module "Microsoft.TeamFoundation.DistributedTask.Task.DevTestLabs" 
# Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Deployment.Internal" 

Write-Output "Deploying $Dacpac"
Write-Verbose "PackageDestinations = $PackageDestinations" -Verbose
Write-Verbose "AdditonalParameters = $AdditonalParameters" -Verbose

# $resourceFQDNKeyName = Get-ResourceFQDNTagKey

# function Get-ResourceConnectionDetails
# {
#     param([object]$resource)

#     $resourceProperties = @{}
#     $resourceName = $resource.Name
#     $resourceId = $resource.Id

#     Write-Verbose "Starting Get-EnvironmentProperty cmdlet call on environment name: $PackageDestinations with resource id: $resourceId(Name : $resourceName) and key: $resourceFQDNKeyName" -Verbose
#     $fqdn = Get-EnvironmentProperty -EnvironmentName $PackageDestinations -Key $resourceFQDNKeyName -Connection $connection -ResourceId $resourceId -TaskContext $distributedTaskContext
#     Write-Verbose "Completed Get-EnvironmentProperty cmdlet call on environment name: $PackageDestinations with resource id: $resourceId(Name : $resourceName) and key: $resourceFQDNKeyName" -Verbose

#     $resourceProperties.fqdn = $fqdn
#     $resourceProperties.credential = Get-ResourceCredentials -resource $resource    
#     $resourceProperties.displayName = $fqdn

#     return $resourceProperties
# }

# function Get-ResourcesProperties
# {
#     param([object]$resources)

#     [hashtable]$resourcesPropertyBag = @{}

#     foreach ($resource in $resources)
#     {
#         $resourceName = $resource.Name
#         $resourceId = $resource.Id
#         Write-Verbose "Get Resource properties for $resourceName (ResourceId = $resourceId)" -Verbose
#         $resourceProperties = Get-ResourceConnectionDetails -resource $resource
#         $resourceProperties.skipCACheckOption = $skipCACheckOption
#         $resourcesPropertyBag.add($resourceId, $resourceProperties)
#     }

#     return $resourcesPropertyBag
# }

# $connection = Get-VssConnection -TaskContext $distributedTaskContext

# # This is temporary fix for filtering 
# Write-Verbose "Starting Register-Environment cmdlet call for environment : $PackageDestinations" -Verbose
# $environment = Register-Environment -EnvironmentName $PackageDestinations -EnvironmentSpecification $PackageDestinations -Connection $connection -TaskContext $distributedTaskContext -ResourceFilter $ResourceFilter
# Write-Verbose "Completed Register-Environment cmdlet call for environment : $PackageDestinations" -Verbose

# Write-Verbose "Starting Get-EnvironmentResources cmdlet call on environment name: $PackageDestinations" -Verbose
# $resources = Get-EnvironmentResources -EnvironmentName $PackageDestinations -TaskContext $distributedTaskContext
# Write-Verbose "Completed Get-EnvironmentResources cmdlet call on environment name: $PackageDestinations" -Verbose

# if ($resources.Count -eq 0)
# {
#   throw "No machine exists under environment: '$PackageDestinations' for deployment"
# }

# $resourcesPropertyBag = Get-ResourcesProperties -resources $resources

# foreach($resource in $resources)
# {
#     $resourceProperties = $resourcesPropertyBag.Item($resource.Id)
#     $machine = $resourceProperties.fqdn
#     $displayName = $resourceProperties.displayName
#     Write-Output (Get-LocalizedString -Key "Deployment started for machine: '{0}'" -ArgumentList $displayName)

#     try
#     {
#         Write-Output "Deploying to $machine/$Database"

#         Write-Output "Sucessfully Deployed to $machine"
#     }
#     catch
#     {
#         throw "Failed to deploy to $machine/$Database"
#     }
# }

$sqlUser = '';
$sqlPassword = '';
$sqlServer = '';

$targetScript = "$sqlServer-Update.sql";

Start-Process sqlpackage -Verbose -NoNewWindow -PassThru -Wait -ArgumentList "/a:Script /op:$targetScript /sf:$Dacpac /TargetServerName:$sqlServer /TargetDatabaseName:$Database /TargetUser:$sqlUser /TargetPassword:$sqlPassword"

Start-Process sqlcmd -Verbose -NoNewWindow -PassThru -Wait -ArgumentList "-S $sqlServer -d $Database -U $sqlUser -P $sqlPassword -i $targetScript"