function Test-PSFrameworkConfig {
	<#
	.SYNOPSIS
		Tests, whether the desired value/state for the PSFramework configuration setting applies.
	
	.DESCRIPTION
		Tests, whether the desired value/state for the PSFramework configuration setting applies.
	
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
	
	.PARAMETER Current
		The object representing the current state.
	
	.EXAMPLE
		PS C:\> Test-PSFrameworkConfig @param

		Tests, whether the desired value/state for the PSFramework configuration setting applies.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[OutputType([bool])]
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
		$ValueType,

		[PSFrameworkConfig]
		$Current
	)
	process {
		if ($Current.Ensure -ne $Ensure) { return $false }
		if ($Ensure -eq 'Absent') { return $true }
		
		try { $intendedValue = [PSFrameworkConfig]::Convert($Value, $ValueType) }
		catch { throw "Error testing $FullName : Failed to convert $Value to $ValueType! $_" }
		$registryValue = $intendedValue
		if ($ValueType -ne 'PsfConfig') { $registryValue = [PSFrameworkConfig]::Serialize($intendedValue) }

		$registryValue -eq $Current.Value
	}
}