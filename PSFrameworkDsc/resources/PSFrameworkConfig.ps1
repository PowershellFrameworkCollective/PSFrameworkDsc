[DscResource()]
class PSFrameworkConfig {
	#region DSC Properties
	[DscProperty(Key)]
	[string]$FullName

	[DscProperty(Mandatory)]
	[Ensure]$Ensure

	<#
    	The scope it is set to.
		Defaults to "SystemDefault"
		DSC can only access the System wide settings.
    #>
	[DscProperty()]
	[Scope]$ConfigScope = 'SystemDefault'
	
	<#
		The value to apply
		Is only mandatory when $Ensure is set to "Present"
    #>
	[DscProperty()]
	[string]$Value

	<#
		The type of the value to apply.
		Tries to parse out the from the string value provided.
		Use PsfConfig to provide the literal notation used by PSFramework for configuration.
		E.G. the result from this:
		[PSFramework.Configuration.ConfigurationHost]::ConvertToPersistedValue(42).TypeQualifiedPersistedValue
		Which would translate to:
		Int:42
	#>
	[DscProperty()]
	[ConfigType]$ValueType

	[DscProperty(NotConfigurable)]
	[Reason[]] $Reasons # Reserved for Azure Guest Configuration
	#endregion DSC Properties

	[void]Set() {
		$param = $this.GetConfigurableDscProperties()
		Set-PSFrameworkConfig @param
	}

	[PSFrameworkConfig]Get() {
		$param = $this.GetConfigurableDscProperties()
		return Get-PSFrameworkConfig @param
	}

	[bool]Test() {
		$param = $this.GetConfigurableDscProperties()
		$current = $this.Get()
		return Test-PSFrameworkConfig @param -Current $current
	}

	[Hashtable] GetConfigurableDscProperties() {
		# This method returns a hashtable of properties with two special workarounds
		# The hashtable will not include any properties marked as "NotConfigurable"
		# Any properties with a ValidateSet of "True","False" will beconverted to Boolean type
		# The intent is to simplify splatting to functions
		# Source: https://gist.github.com/mgreenegit/e3a9b4e136fc2d510cf87e20390daa44
		$dscProperties = @{}
		foreach ($property in [PSFrameworkConfig].GetProperties().Name) {
			# Checks if "NotConfigurable" attribute is set
			$notConfigurable = [PSFrameworkConfig].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.DscPropertyAttribute] }).NotConfigurable
			if (!$notConfigurable) {
				$paramValue = $this.$property
				# Gets the list of valid values from the ValidateSet attribute
				$validateSet = [PSFrameworkConfig].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
				if ($validateSet) {
					# Workaround for boolean types
					if ($null -eq (Compare-Object @('True', 'False') $validateSet)) {
						$paramValue = [System.Convert]::ToBoolean($this.$property)
					}
				}
				# Add property to new
				$dscProperties.add($property, $paramValue)
			}
		}
		return $dscProperties
	}

	static [object] Convert([string]$Value, [ConfigType]$ValueType) {
		switch ($ValueType) {
			NotSpecified { return $Value }
			Bool { return $Value -eq 'true' -or $Value -eq '1' }
			Int { return [int]$Value }
			UInt { return [uint32]$Value }
			Int16 { return [Int16]$Value }
			Int32 { return [Int32]$Value }
			Int64 { return [Int64]$Value }
			UInt16 { return [UInt16]$Value }
			UInt32 { return [UInt32]$Value }
			UInt64 { return [Uint64]$Value }
			Double { return [double]$Value }
			String { return $Value }
			TimeSpan { return [Timespan]$Value }
			DateTime { return [DateTime]$Value }
			ConsoleColor { return [ConsoleColor]$Value }
			BoolArray { return [PSFrameworkConfig]::ConvertArray($Value, 'Bool') }
			IntArray { return [PSFrameworkConfig]::ConvertArray($Value, 'Int') }
			UIntArray { return [PSFrameworkConfig]::ConvertArray($Value, 'UInt') }
			Int16Array { return [PSFrameworkConfig]::ConvertArray($Value, 'Int16') }
			Int32Array { return [PSFrameworkConfig]::ConvertArray($Value, 'Int32') }
			Int64Array { return [PSFrameworkConfig]::ConvertArray($Value, 'Int64') }
			UInt16Array { return [PSFrameworkConfig]::ConvertArray($Value, 'UInt16') }
			UInt32Array { return [PSFrameworkConfig]::ConvertArray($Value, 'UInt32') }
			UInt64Array { return [PSFrameworkConfig]::ConvertArray($Value, 'UInt64') }
			DoubleArray { return [PSFrameworkConfig]::ConvertArray($Value, 'Double') }
			StringArray { return [PSFrameworkConfig]::ConvertArray($Value, 'String') }
			TimeSpanArray { return [PSFrameworkConfig]::ConvertArray($Value, 'TimeSpan') }
			DateTimeArray { return [PSFrameworkConfig]::ConvertArray($Value, 'DateTime') }
			ConsoleColorArray { return [PSFrameworkConfig]::ConvertArray($Value, 'ConsoleColor') }
			PsfConfig { return $Value }
			default { return $Value }
		}
		# PowerShell Parser does not detect when there is no path in a switch statement that ends with a return.
		throw "Unhandled conversion error: Developer failed to do it right."
	}

	static hidden [object] ConvertArray([string]$Value, [ConfigType]$ValueType) {
		if ($Value -match 'þ') { $values = $Value -split 'þ' }
		else { $values = $Value -split '\|' }

		$results = foreach ($item in $Values) {
			[PSFrameworkConfig]::Convert($item, $ValueType)
		}
		return @($results)
	}

	static [bool] IsLegalType($Object) {
		$typeName = $Object.GetType().FullName
		
		if ($typeName -eq "System.Object[]") {
			foreach ($item in $Object) {
				if (-not ([PSFrameworkConfig]::IsLegalType($item))) { return $false }
			}
			return $true
		}
		
		$legalTypes = @(
			'System.Boolean',
			'System.Int16',
			'System.Int32',
			'System.Int64',
			'System.UInt16',
			'System.UInt32',
			'System.UInt64',
			'System.Double',
			'System.String',
			'System.TimeSpan',
			'System.DateTime',
			'System.ConsoleColor'
		)
		
		if ($legalTypes -contains $typeName) { return $true }
		return $false
	}
	
	static [string] Serialize($Object) {
		switch ($Object.GetType().FullName) {
			"System.Object[]" {
				$list = @()
				foreach ($item in $Object) {
					$list += [PSFrameworkConfig]::Serialize($item)
				}
				return "array:$($list -join "þþþ")"
			}
			"System.Boolean" {
				if ($Object) { return "bool:true" }
				else { return "bool:false" }
			}
			"System.Int16" { return "int:$Object" }
			"System.Int32" { return "int:$Object" }
			"System.Int64" { return "long:$Object" }
			"System.UInt16" { return "int:$Object" }
			"System.UInt32" { return "int:$Object" }
			"System.UInt64" { return "long:$Object" }
			"System.Double" { return "double:$Object" }
			"System.String" { return "string:$Object" }
			"System.TimeSpan" { return "timespan:$($Object.Ticks)" }
			"System.DateTime" { return "datetime:$($Object.Ticks)" }
			"System.ConsoleColor" { return "consolecolor:$Object" }
			default { throw "$($Object.GetType().FullName) was not recognized as a legal type!" }
		}
		
		return "<illegal data>"
	}
	
	static [object] DeSerialize([string]$Item) {
		$index = $Item.IndexOf(":")
		if ($index -lt 1) { throw "No type identifier found!" }
		$type = $Item.Substring(0, $index).ToLower()
		$content = $Item.Substring($index + 1)
		
		switch ($type) {
			"bool" {
				if ($content -eq "true") { return $true }
				if ($content -eq "1") { return $true }
				if ($content -eq "false") { return $false }
				if ($content -eq "0") { return $false }
				throw "Failed to interpret as bool: $content"
			}
			"int" { return ([int]$content) }
			"double" { return [double]$content }
			"long" { return [long]$content }
			"string" { return $content }
			"timespan" { return (New-Object System.TimeSpan($content)) }
			"datetime" { return (New-Object System.DateTime($content)) }
			"consolecolor" { return ([System.ConsoleColor]$content) }
			"array" {
				$list = @()
				foreach ($item in ($content -split "þþþ")) {
					$list += [PSFrameworkConfig]::Deserialize($item)
				}
				return $list
			}
			
			default { throw "Unknown type identifier" }
		}
		
		return $null
	}
}