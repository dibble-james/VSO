param(
    [string]$files,
    [string]$username,
    [string]$password,
    [string]$url,
    [string]$redirectStderr,
    [string]$options
)

Write-Verbose "Entering script cURLUploader.ps1"
Write-Verbose "files = $files"
Write-Verbose "username = $username"
Write-Verbose "url = $url"
Write-Verbose "redirectStderr = $redirectStderr"
Write-Verbose "options = $options"

# Import the Task dll that has all the cmdlets we need for Build
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Common"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"

$redirectStderrChecked = Convert-String $redirectStderr Boolean
Write-Verbose "redirectStderrChecked (converted) = $redirectStderrChecked"

#Verify curl is installed correctly
try
{
    $curl = Get-Command curl.exe
    $curlPath = $curl.Path
    Write-Verbose "Found curl at $curlPath"
}
catch
{
    throw 'Unable to find cURL. Verify it is installed correctly on the build agent: http://curl.haxx.se.'
}

if (!$files)
{
    throw "Files parameter not set on script"
}

if (!$url)
{
    throw "URL parameter not set on script"
}

Write-Verbose "No Pattern found in files parameter."
Set-Location $files
$foundFiles = Get-ChildItem -Recurse | Where-Object{!($_.PSIsContainer)} | Resolve-Path -Relative
    
if ($redirectStderrChecked) 
{
    $args = "--stderr -"
}

$args = "$args $options"

# cURL even on Windows expects forward slash as path separator. 
if ($username -or $password)
{
    $args = "$args -u `"$username`"" + ":" + "`"$password`""
}

ForEach($file in $foundFiles)
{
    $destination = ($url + ($file.TrimStart("."))) -replace "\\","/"
    $source = (Resolve-Path $file) -replace "\\","/"

    $fileArgs = "$args -T {`"$source`"} `"$destination`""

    Invoke-Tool -Path $curlPath -Arguments $fileArgs
}

Write-Verbose "Leaving script cURLUploader.ps1"