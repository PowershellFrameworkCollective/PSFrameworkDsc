class ConfigHelper {
	[Scope] $Scope

	[hashtable]$Config = @{ }

	ConfigHelper([Scope]$Scope) {
		$this.Scope = $Scope
	}

	[void]Load() {
		$providerProps = 'PSPath','PSParentPath','PSChildName','PSDrive','PSProvider'

		switch ($this.Scope) {
			SystemDefault {
				if (-not (Test-Path -Path $script:config.PathDefault)) {
					$this.Config = @{}
					return
				}

				$newConfig = @{}
				$regItem = Get-ItemProperty -Path $script:config.PathDefault
				foreach ($property in $regItem.PSObject.Properties) {
					if ($property.Name -in $providerProps) { continue }
					$newConfig[$property.Name] = $property.Value
				}
				$this.Config = $newConfig
			}
			SystemEnforced {
				if (-not (Test-Path -Path $script:config.PathEnforced)) {
					$this.Config = @{}
					return
				}

				$newConfig = @{}
				$regItem = Get-ItemProperty -Path $script:config.PathEnforced
				foreach ($property in $regItem.PSObject.Properties) {
					if ($property.Name -in $providerProps) { continue }
					$newConfig[$property.Name] = $property.Value
				}
				$this.Config = $newConfig
			}
			default { throw "Scope not implemented: $($this.Scope)" }
		}
	}
	[void]Write([string]$FullName, [object]$Value, [bool]$IsConfigString = $false) {
		$valueToWrite = $Value
		if (-not $IsConfigString) { $valueToWrite = [ConfigHelper]::Serialize($Value) }
		if ($valueToWrite -eq $this.Config[$FullName]) { return }

		switch ($this.Scope) {
			SystemDefault {
				if (-not (Test-Path -Path $script:config.PathDefault)) {
					$null = New-Item -Path $script:config.PathDefault -Force
				}

				Set-ItemProperty -Path $script:config.PathDefault -Value $valueToWrite -Name $FullName -Force
			}
			SystemEnforced {
				if (-not (Test-Path -Path $script:config.PathEnforced)) {
					$null = New-Item -Path $script:config.PathEnforced -Force
				}

				Set-ItemProperty -Path $script:config.PathEnforced -Value $valueToWrite -Name $FullName -Force
			}
			default { throw "Scope not implemented: $($this.Scope)" }
		}

		$this.Load()
	}
	[void]Remove([string]$FullName) {
		if ($this.Config.Keys -notcontains $FullName) { return }

		switch ($this.Scope) {
			SystemDefault {
				$fail = $null
				Remove-ItemProperty -Path $script:config.PathDefault -Name $FullName -Force -ErrorAction SilentlyContinue -ErrorVariable fail
				if ($fail -and $fail.CategoryInfo.Category -ne 'InvalidArgument') { throw $fail }
			}
			SystemEnforced {
				$fail = $null
				Remove-ItemProperty -Path $script:config.PathEnforced -Name $FullName -Force -ErrorAction SilentlyContinue -ErrorVariable fail
				if ($fail -and $fail.CategoryInfo.Category -ne 'InvalidArgument') { throw $fail }
			}
			default { throw "Scope not implemented: $($this.Scope)" }
		}
	}
	[object]GetConverted([string]$FullName) {
		if ($this.Config.Keys -notcontains $FullName) { return $null }

		return [ConfigHelper]::Deserialize($this.Config[$FullName])
	}

	[bool]Compare([object]$Value, [string]$FullName) {
		return $this.Compare($Value, $FullName, { $null -eq $args[0] })
	}
	[bool]Compare([object]$Value, [string]$FullName, [scriptblock]$NullCondition = { $null -eq $args[0] }) {
		$isNull = & $NullCondition $Value
		if ($isNull) {
			return $this.Config.Keys -notcontains $FullName
		}

		$resValue = [ConfigHelper]::Serialize($Value)

		return $resValue -eq $this.Config[$FullName]
	}

	[void]Apply([string]$FullName, [object]$Value) {
		$this.Apply($FullName, $Value, { $null -eq $args[0] })
	}
	[void]Apply([string]$FullName, [object]$Value, [scriptblock]$NullCondition) {
		$isNull = & $NullCondition $Value
		
		if ($isNull) {
			if ($this.Config.Keys -contains $FullName) {
				$this.Remove($FullName)
			}
			
			return
		}

		$this.Write($FullName, $Value, $false)
	}

	#region Statics
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
			BoolArray { return [ConfigHelper]::ConvertArray($Value, 'Bool') }
			IntArray { return [ConfigHelper]::ConvertArray($Value, 'Int') }
			UIntArray { return [ConfigHelper]::ConvertArray($Value, 'UInt') }
			Int16Array { return [ConfigHelper]::ConvertArray($Value, 'Int16') }
			Int32Array { return [ConfigHelper]::ConvertArray($Value, 'Int32') }
			Int64Array { return [ConfigHelper]::ConvertArray($Value, 'Int64') }
			UInt16Array { return [ConfigHelper]::ConvertArray($Value, 'UInt16') }
			UInt32Array { return [ConfigHelper]::ConvertArray($Value, 'UInt32') }
			UInt64Array { return [ConfigHelper]::ConvertArray($Value, 'UInt64') }
			DoubleArray { return [ConfigHelper]::ConvertArray($Value, 'Double') }
			StringArray { return [ConfigHelper]::ConvertArray($Value, 'String') }
			TimeSpanArray { return [ConfigHelper]::ConvertArray($Value, 'TimeSpan') }
			DateTimeArray { return [ConfigHelper]::ConvertArray($Value, 'DateTime') }
			ConsoleColorArray { return [ConfigHelper]::ConvertArray($Value, 'ConsoleColor') }
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
			[ConfigHelper]::Convert($item, $ValueType)
		}
		return @($results)
	}

	static [bool] IsLegalType($Object) {
		$typeName = $Object.GetType().FullName
		
		if ($typeName -eq "System.Object[]") {
			foreach ($item in $Object) {
				if (-not ([ConfigHelper]::IsLegalType($item))) { return $false }
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
					$list += [ConfigHelper]::Serialize($item)
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
			default {
				if ($_ -notmatch '\[\]$') {
					throw "$_ was not recognized as a legal type!"
				}

				$list = @()
				foreach ($item in $Object) {
					$list += [ConfigHelper]::Serialize($item)
				}
				return "array:$($list -join "þþþ")"
			}
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
					$list += [ConfigHelper]::Deserialize($item)
				}
				return $list
			}
			
			default { throw "Unknown type identifier" }
		}
		
		return $null
	}
	#endregion Statics
}