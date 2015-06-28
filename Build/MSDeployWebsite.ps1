[CmdletBinding()]
param(
	[Parameter(Mandatory)][string] $WebDeployPackage,
	[Parameter(Mandatory)][string] $PackageDestinations,
	[Parameter(Mandatory)][string] $VirtualDirectory,
	[Parameter(Mandatory)][string] $WebDeployUser,
	[Parameter(Mandatory)][string] $WebDeployPassword,
    [string] $AgentType = "MSDepSvc",
	[Switch] $AllowUntrusted,
    [Switch] $MergeBuildVariables
)

DynamicParam {
    Add-PSSnapin WDeploySnapin3.0

    $deploymentParameters = Get-WDParameters $WebDeployPackage

    $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

    ForEach($deploymentParameter in $deploymentParameters.GetEnumerator())
    {
        $parameterName = $deploymentParameter.Name -replace "[^a-zA-Z0-9]", ""

        $dynamicPackageParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($dynamicPackageParameterAttribute)
        $dynamicPackageParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($parameterName, [string], $attributeCollection)
        
        $paramDictionary.Add($parameterName, $dynamicPackageParameter)
    }

    return $paramDictionary
} 

Process {
    Write-Host -Foreground Green "Deploying $WebDeployPackage"

    Add-PSSnapin WDeploySnapin3.0

    $deploymentParameters = Get-WDParameters $WebDeployPackage

    $environmentVariables = Get-ChildItem Env:

    $environmentVariablesVerbose = ($environmentVariables | Out-String)

    Write-Verbose "Environment Variables Parameters $environmentVariablesVerbose" 

    $mergedDeploymentParameters = @{};

    ForEach($deploymentParameter in $deploymentParameters.GetEnumerator())
    {
        $parameterName = $deploymentParameter.Name -replace "[^a-zA-Z0-9]", ""

        # Default the parameter value to the default value in SetParameters.xml
        $parameterValue = $deploymentParameter.Value

        # Try getting the parameter from environment variables 
        if($MergeBuildVariables -and $environmentVariables[$parameterName])
        {
            $parameterValue = $environmentVariables[$parameterName]
        }

        # Explicit deployment parameter trumps all
        if($PsBoundParameters[$parameterName])
        {
            $parameterValue = $PsBoundParameters[$parameterName]
        }
        
        $mergedDeploymentParameters[$deploymentParameter.Name] = $parameterValue
    }

    $mergedDeploymentParameters['IIS Web Application Name'] = $VirtualDirectory

    $packageParametersVerbose = ($mergedDeploymentParameters | Out-String)

    Write-Verbose "Package Parameters $packageParametersVerbose" 

    ForEach($destination in $PackageDestinations.Split(','))
    {
        try
        {
            Write-Host -Foreground Green "Deploying to $destination/$VirtualDirectory"

            $settingsFilename = "$WebDeployPackage.$destination.publishsettings"

            New-WDPublishSettings -AllowUntrusted -EncryptPassword -ComputerName $destination -UserId $WebDeployUser -Password $WebDeployPassword -FileName "$settingsFilename" -AgentType $AgentType

            Write-Verbose "Using $settingsFilename"

            Restore-WDPackage -Package $WebDeployPackage -Verbose -DestinationPublishSettings $settingsFilename -ErrorAction Stop -Parameters $mergedDeploymentParameters

            Write-Host -Foreground Green "Sucessfully Deployed to $destination"
        }
        catch
        {
            Write-Host -Foreground Red "Failed to deploy to $destination`n$_"

            Exit 1
        }
    }
}