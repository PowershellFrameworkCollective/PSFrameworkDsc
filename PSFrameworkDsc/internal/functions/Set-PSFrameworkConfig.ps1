function Set-PSFrameworkConfig {
	<#
	.SYNOPSIS
		Applies the desired value for the PSFramework configuration setting.
	
	.DESCRIPTION
		Applies the desired value for the PSFramework configuration setting.
	
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
		PS C:\> Set-PSFrameworkConfig @param

		Applies the desired value for the PSFramework configuration setting.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
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
		if ($ConfigScope -eq 'SystemDefault') { $path = $script:config.PathDefault }
		else { $path = $script:config.PathEnforced }

		if ($Ensure -eq 'Absent') {
			if (-not (Test-Path -Path $path)) { return }

			$current = Get-ItemProperty -Path $path
			if ($current.PSObject.Properties.Name -notcontains $FullName) { return }
			
			# Ensure the casing is exact, just in case
			$name = $current.PSObject.Properties.Name | Where-Object { $_ -eq $FullName }
			Remove-ItemProperty -Path $path -Name $name -ErrorAction Stop

			return
		}

		try { $intendedValue = [PSFrameworkConfig]::Convert($Value, $ValueType) }
		catch { throw "Error setting $FullName : Failed to convert $Value to $ValueType! $_" }
		if ($ValueType -ne 'PsfConfig' -and -not [PSFrameworkConfig]::IsLegalType($intendedValue)) {
			if ($null -eq $intendedValue) { $convertedValueType = '<null>' }
			else { $convertedValueType = $intendedValue.GetType() }
			throw "Datatype not supported: $($convertedValueType)"
		}

		if (-not (Test-Path $path)) {
			$null = New-Item $Path -Force
		}

		$registryValue = $intendedValue
		if ($ValueType -ne 'PsfConfig') { $registryValue = [PSFrameworkConfig]::Serialize($intendedValue) }

		Set-ItemProperty -Path $path -Name $FullName -Value $registryValue -ErrorAction Stop
	}
}