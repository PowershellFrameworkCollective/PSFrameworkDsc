class PsfLoggingHelper {
	[string] $ProviderName
	[string] $InstanceName

	[object] $LogConfig

	PsfLoggingHelper([object]$LogObject, [string]$ProviderName) {
		$this.LogConfig = $LogObject
		$this.ProviderName = $ProviderName
		$this.InstanceName = $LogObject.InstanceName
	}

	[hashtable]Get() {
		if (-not $this.InstanceName) { throw "Cannot read Instance configuration - no instance defined yet!" }

		$helper = [ConfigHelper]::new('SystemDefault')
		$helper.Load()

		$data = @{ }

		$baseName = "LoggingProvider.$($this.ProviderName).$($this.InstanceName)"
		$names = 'Enabled', 'ExcludeFunctions', 'ExcludeModules', 'ExcludeTags', 'IncludeFunctions', 'IncludeModules', 'IncludeTags', 'MaxLevel', 'MinLevel'
		foreach ($name in $names) {
			if ($helper.Config.Keys -notcontains "$baseName.$name") { continue }
			$data[$name] = $helper.Config["$baseName.$name"]
		}

		return $data
	}

	[bool]Test() {
		$helper = [ConfigHelper]::new('SystemDefault')
		$helper.Load()

		$baseName = "LoggingProvider.$($this.ProviderName).$($this.InstanceName)"

		if ($this.LogConfig.Enabled -ne $helper.GetConverted("$baseName.Enabled")) { return $false }
		if (-not $helper.Compare($this.LogConfig.MinLevel, "$baseName.MinLevel", { $args[0] -lt 1 })) { return $false }
		if (-not $helper.Compare($this.LogConfig.MaxLevel, "$baseName.MaxLevel", { $args[0] -lt 1 })) { return $false }

		$names = 'ExcludeFunctions', 'ExcludeModules', 'ExcludeTags', 'IncludeFunctions', 'IncludeModules', 'IncludeTags'
		foreach ($name in $names) {
			if (-not $helper.Compare($this.LogConfig.$name, "$baseName.$name")) { return $false }
		}

		return $true
	}

	[void]Set() {
		$helper = [ConfigHelper]::new('SystemDefault')
		$helper.Load()

		$baseName = "LoggingProvider.$($this.ProviderName).$($this.InstanceName)"

		if ($this.LogConfig.Ensure -eq 'Absent') {
			$names = 'Enabled', 'ExcludeFunctions', 'ExcludeModules', 'ExcludeTags', 'IncludeFunctions', 'IncludeModules', 'IncludeTags', 'MaxLevel', 'MinLevel'
			foreach ($name in $names) {
				$helper.Remove("$baseName.$name")
			}
			return
		}

		$helper.Write("$baseName.Enabled", $this.LogConfig.Enabled, $false)
		$helper.Apply("$baseName.MinLevel", $this.LogConfig.MinLevel, { $args[0] -lt 1 })
		$helper.Apply("$baseName.MaxLevel", $this.LogConfig.MaxLevel, { $args[0] -lt 1 })

		$names = 'ExcludeFunctions', 'ExcludeModules', 'ExcludeTags', 'IncludeFunctions', 'IncludeModules', 'IncludeTags'
		foreach ($name in $names) {
			$helper.Apply("$baseName.$name", $this.LogConfig.$name)
		}
	}

	[void]Clear() {
		$helper = [ConfigHelper]::new('SystemDefault')
		$helper.Load()

		$baseName = "LoggingProvider.$($this.ProviderName).$($this.InstanceName)"
		$names = 'Enabled', 'ExcludeFunctions', 'ExcludeModules', 'ExcludeTags', 'IncludeFunctions', 'IncludeModules', 'IncludeTags', 'MaxLevel', 'MinLevel'
		foreach ($name in $names) {
			$helper.Remove("$baseName.$name")
		}
	}
}