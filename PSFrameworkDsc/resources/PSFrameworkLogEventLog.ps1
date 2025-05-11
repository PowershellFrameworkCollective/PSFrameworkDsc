[DscResource()]
class PSFrameworkLogEventLog {
	[DscProperty(Mandatory)]
	[Ensure]$Ensure

	#region Logging Provider Settings
	[DscProperty(Key)]
	[string]$InstanceName

	[DscProperty()]
	[string]$LogName

	[DscProperty()]
	[string]$Source

	[DscProperty()]
	[bool]$UseFallback = $true

	[DscProperty()]
	[int]$Category

	[DscProperty()]
	[int]$InfoID

	[DscProperty()]
	[int]$WarningID

	[DscProperty()]
	[int]$ErrorID

	[DscProperty()]
	[string]$ErrorTag

	[DscProperty()]
	[string]$TimeFormat

	[DscProperty()]
	[bool]$NumericTagAsID
	#endregion Logging Provider Settings

	#region Common Logging Settings
	[DscProperty()]
	[bool]$Enabled = $true

	[DscProperty()]
	[string[]]$IncludeModules
	
	[DscProperty()]
	[string[]]$ExcludeModules
	
	[DscProperty()]
	[string[]]$IncludeFunctions
	
	[DscProperty()]
	[string[]]$ExcludeFunctions
	
	[DscProperty()]
	[string[]]$IncludeTags
	
	[DscProperty()]
	[string[]]$ExcludeTags
	
	[DscProperty()]
	[int]$MinLevel
	
	[DscProperty()]
	[int]$MaxLevel
	#endregion Common Logging Settings

	#region DSC Properties
	[DscProperty(NotConfigurable)]
	[Reason[]] $Reasons # Reserved for Azure Guest Configuration
	#endregion DSC Properties

	hidden [hashtable] $PropertyMap = @{
		LogName        = { $false }
		Source         = { $false }
		UseFallback    = { $args[0] }
		Category       = { 1 -gt $args[0] }
		InfoID         = { 1 -gt $args[0] }
		WarningID      = { 1 -gt $args[0] }
		ErrorID        = { 1 -gt $args[0] }
		ErrorTag       = { -not $args[0] }
		TimeFormat     = { -not $args[0] }
		NumericTagAsID = { -not $args[0] }
	}

	[void]Set() {
		$this.AssertConfig()

        # Apply Desired State
		$logHelper = [PsfLoggingHelper]::new($this, 'Eventlog')
		$extHelper = [ExtendedConfigHelper]::New($this, 'SystemDefault', "PSFramework.Logging.Eventlog.$($this.InstanceName)", $this.PropertyMap)

		if ($this.Ensure -eq 'Absent') {
			$extHelper.Clear()
			$logHelper.Clear()
			return
		}

		$extHelper.Set()
		$logHelper.Set()
	}

	[PSFrameworkLogEventLog]Get() {
		# Return current actual state

		$result = [PSFrameworkLogEventLog]::new()
		$result.InstanceName = $this.InstanceName
		$result.Ensure = 'Absent'

		$logHelper = [PsfLoggingHelper]::new($this, 'Eventlog')
		$extHelper = [ExtendedConfigHelper]::New($this, 'SystemDefault', "PSFramework.Logging.Eventlog.$($this.InstanceName)", $this.PropertyMap)

		foreach ($pair in $logHelper.Get().GetEnumerator()) {
			$result.Ensure = 'Present'
			$result.$($pair.Key) = $pair.Value
		}

		foreach ($pair in $extHelper.Get().GetEnumerator()) {
			$result.Ensure = 'Present'
			$result.$($pair.Key) = $pair.Value
		}

		return $result
	}

	[bool]Test() {
		$this.AssertConfig()

		$logHelper = [PsfLoggingHelper]::new($this, 'Eventlog')
		$extHelper = [ExtendedConfigHelper]::New($this, 'SystemDefault', "PSFramework.Logging.Eventlog.$($this.InstanceName)", $this.PropertyMap)

		if ($this.Ensure -eq 'Absent') {
			if ($logHelper.Get().Count -gt 0) { return $false }
			if ($extHelper.Get().Count -gt 0) { return $false }
			return $true
		}

		# Test Common Provider Settings
        
		if (-not $logHelper.Test()) { return $false }
		if (-not $extHelper.Test()) { return $false }
		return $true
	}

	[PsfLoggingHelper]GetLogHelper() {
		return [PsfLoggingHelper]::new($this, 'Eventlog')
	}
	[ExtendedConfigHelper]GetCfgHelper() {
		return [ExtendedConfigHelper]::New($this, 'SystemDefault', "PSFramework.Logging.Eventlog.$($this.InstanceName)", $this.PropertyMap)
	}

	[void]AssertConfig() {
		if ($this.Ensure -eq 'Absent') { return }

		if (-not $this.LogName) { throw "Missing Setting: LogName!" }
		if (-not $this.Source) { throw "Missing Setting: Source!" }
	}
}