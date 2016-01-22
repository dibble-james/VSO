Write-Host "Working Directory" (Get-Item -Path ".\" -Verbose).FullName

dnvm install latest

dnu restore