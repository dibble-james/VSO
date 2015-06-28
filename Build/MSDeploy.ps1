[CmdletBinding()]
param(
	[Parameter(Mandatory)][string] $WebDeployPackage,
	[Parameter(Mandatory)][string] $PackageDestinations,
	[Parameter(Mandatory)][string] $VirtualDirectory,
	[Parameter(Mandatory)][string] $WebDeployUser,
	[Parameter(Mandatory)][string] $WebDeployPassword,
    [string] $AgentType = "MSDepSvc",
	[Switch] $AllowUntrusted,
	[string] $PackageParameters
)

Write-Host -Foreground Green "Deploying $WebDeployPackage"

Add-PSSnapin WDeploySnapin3.0

$packageParameters = Get-WDParameters $WebDeployPackage

if($WebDeployParameters)
{
	$deploymentValuesAsHashTable = ConvertFrom-StringData $WebDeployParameters
	            
	ForEach($deploymentValue in  $deploymentValuesAsHashTable.GetEnumerator())
	{
		if(!$packageParameters.ContainsKey($deploymentValue.Name))
		{
			Write-Host -Foreground Red "Package does not contain parameter $($deploymentValue.Name)"
			Exit 1
		}

	    $packageParameters[$deploymentValue.Name] = $deploymentValue.Value
	}	
}

$packageParameters['IIS Web Application Name'] = $VirtualDirectory

$packageParametersVerbose = ($packageParameters | Out-String)

Write-Verbose "Package Parameters $packageParametersVerbose" 

ForEach($destination in $PackageDestinations.Split(','))
{
	try
	{
		Write-Host -Foreground Green "Deploying to $destination/$VirtualDirectory"

		$settingsFilename = "$WebDeployPackage.$destination.publishsettings"

		New-WDPublishSettings -AllowUntrusted -EncryptPassword -ComputerName $destination -UserId $WebDeployUser -Password $WebDeployPassword -FileName "$settingsFilename" -AgentType $AgentType

		Write-Verbose "Using $settingsFilename"

		Restore-WDPackage -Package $WebDeployPackage -Verbose -DestinationPublishSettings $settingsFilename -ErrorAction Stop -Parameters $packageParameters

		Write-Host -Foreground Green "Sucessfully Deployed to $destination"
	}
	catch
	{
		Write-Host -Foreground Red "Failed to deploy to $destination`n$_"

		Exit 1
	}
}