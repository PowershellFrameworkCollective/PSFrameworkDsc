function Get-PSFrameworkConfig {
	<#
	.SYNOPSIS
		Returns the current state of the configuration setting.
	
	.DESCRIPTION
		Returns the current state of the configuration setting.
	
	.PARAMETER FullName
		The full name of the PSFramework configuration setting.
	
	.PARAMETER Ensure
		Whether it should be present or absent.
	
	.PARAMETER ConfigScope
		What scope it should be applied to.
	
	.PARAMETER Value
		The value it should have.

	.PARAMETER ValueType
		The type of the value that should be defined.
		Used because DSC does not allow Object types, thus requiring conversion afterwards.
	
	.EXAMPLE
		PS C:\> Get-PSFramework @param

		Returns the current state of the configuration setting.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$FullName,

		[Parameter(Mandatory = $true)]
		[Ensure]
		$Ensure,

		[Scope]
		$ConfigScope,

		[string]
		$Value,

		[ConfigType]
		$ValueType
	)

	process {
		$result = [PSFrameworkConfig]::new()
		$result.ConfigScope = $ConfigScope
		$result.FullName = $FullName

		if ($ConfigScope -eq 'SystemDefault') { $path = $script:config.PathDefault }
		else { $path = $script:config.PathEnforced }

		$result.Ensure = 'Absent'
		$item = Get-ItemProperty -Path $path -Name $FullName -ErrorAction Ignore
		
		if ($item -and $item.PSObject.Properties.Name -contains $FullName) {
			$result.Ensure = 'Present'
			$result.Value = $item.$FullName
		}

		$result
	}
}