[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $RollbarAccessToken,
    [Parameter()][string] $Environment,
    [Parameter()][string] $Revision,
    [Parameter()][string] $LocalUsername,
    [Parameter()][string] $RollbarUsername,
    [Parameter()][string] $Comment
)

Write-Verbose "Entering RollbarDeploy.ps1" -Verbose

try
{
    $postParams = @{
        access_token = $RollbarAccessToken;
        environment = $Environment;
        revision = $Revision;
        local_username = $LocalUsername;
        rollbar_username = $RollbarUsername;
        comment = $Comment;
    }

    Invoke-WebRequest -Uri https://api.rollbar.com/api/1/deploy -Method POST -Body $postParams
}
catch 
{
    Write-Host "Failed to notify Rollbar of deployment`n$_"    
}

Write-Verbose "Exiting RollbarDeploy.ps1" -Verbose