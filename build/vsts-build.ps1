<#
This script publishes the module to the gallery.
It expects as input an ApiKey authorized to publish the module.

Insert any build steps you may need to take before publishing it here.
#>
param (
	$ApiKey,
	
	$WorkingDirectory,
	
	$Repository = 'PSGallery',
	
	[switch]
	$LocalRepo,
	
	[switch]
	$SkipPublish,
	
	[switch]
	$AutoVersion
)

#region Handle Working Directory Defaults
if (-not $WorkingDirectory)
{
	if ($env:RELEASE_PRIMARYARTIFACTSOURCEALIAS)
	{
		$WorkingDirectory = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
	}
	else { $WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY }
}
if (-not $WorkingDirectory) { $WorkingDirectory = Split-Path $PSScriptRoot }
#endregion Handle Working Directory Defaults

# Prepare publish folder
Write-Host "Creating and populating publishing directory"
$publishDir = New-Item -Path $WorkingDirectory -Name publish -ItemType Directory -Force
Copy-Item -Path "$($WorkingDirectory)\PSFrameworkDsc" -Destination $publishDir.FullName -Recurse -Force

#region Gather text data to compile
$text = @('$script:ModuleRoot = $PSScriptRoot')

# Gather Classes
Get-ChildItem -Path "$($publishDir.FullName)\PSFrameworkDsc\internal\classes\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}

# Gather DSC Resources
$resourceNames = Get-ChildItem -Path "$($publishDir.FullName)\PSFrameworkDsc\resources\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName) -replace '(?m)^using', '# using' # (?m) turns "^" into "Start of line", rather than "Start of text"
	$_.BaseName
}
Update-ModuleManifest -Path "$($publishDir.FullName)\PSFrameworkDsc\PSFrameworkDsc.psd1" -DscResourcesToExport @($resourceNames)

# Gather commands
Get-ChildItem -Path "$($publishDir.FullName)\PSFrameworkDsc\internal\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}
Get-ChildItem -Path "$($publishDir.FullName)\PSFrameworkDsc\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}

# Gather scripts
Get-ChildItem -Path "$($publishDir.FullName)\PSFrameworkDsc\internal\scripts\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}

#region Update the psm1 file & Cleanup
[System.IO.File]::WriteAllText("$($publishDir.FullName)\PSFrameworkDsc\PSFrameworkDsc.psm1", ($text -join "`n`n"), [System.Text.Encoding]::UTF8)
Remove-Item -Path "$($publishDir.FullName)\PSFrameworkDsc\internal" -Recurse -Force
Remove-Item -Path "$($publishDir.FullName)\PSFrameworkDsc\functions" -Recurse -Force
Remove-Item -Path "$($publishDir.FullName)\PSFrameworkDsc\resources" -Recurse -Force
#endregion Update the psm1 file & Cleanup

#region Updating the Module Version
if ($AutoVersion)
{
	Write-Host  "Updating module version numbers."
	try { [version]$remoteVersion = (Find-Module 'PSFrameworkDsc' -Repository $Repository -ErrorAction Stop).Version }
	catch
	{
		throw "Failed to access $($Repository) : $_"
	}
	if (-not $remoteVersion)
	{
		throw "Couldn't find PSFrameworkDsc on repository $($Repository) : $_"
	}
	$newBuildNumber = $remoteVersion.Build + 1
	[version]$localVersion = (Import-PowerShellDataFile -Path "$($publishDir.FullName)\PSFrameworkDsc\PSFrameworkDsc.psd1").ModuleVersion
	Update-ModuleManifest -Path "$($publishDir.FullName)\PSFrameworkDsc\PSFrameworkDsc.psd1" -ModuleVersion "$($localVersion.Major).$($localVersion.Minor).$($newBuildNumber)"
}
#endregion Updating the Module Version

#region Publish
if ($SkipPublish) { return }
if ($LocalRepo)
{
	# Dependencies must go first
	Write-Host  "Creating Nuget Package for module: PSFramework"
	New-PSMDModuleNugetPackage -ModulePath (Get-Module -Name PSFramework).ModuleBase -PackagePath .
	Write-Host  "Creating Nuget Package for module: PSFrameworkDsc"
	New-PSMDModuleNugetPackage -ModulePath "$($publishDir.FullName)\PSFrameworkDsc" -PackagePath .
}
else
{
	# Publish to Gallery
	Write-Host  "Publishing the PSFrameworkDsc module to $($Repository)"
	Publish-Module -Path "$($publishDir.FullName)\PSFrameworkDsc" -NuGetApiKey $ApiKey -Force -Repository $Repository
}
#endregion Publish