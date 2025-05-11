[DscResource()]
class PSFrameworkLogFile {
	[DscProperty(Mandatory)]
	[Ensure]$Ensure

	#region Logging Provider Settings
	[DscProperty(Key)]
	[string]$InstanceName

	[DscProperty()]
	[string]$CsvDelimiter = ','

	[DscProperty()]
	[string]$FilePath

	[DscProperty()]
	[string]$FileType = 'csv'

	[DscProperty()]
	[string[]]$Headers = @('ComputerName', 'File', 'FunctionName', 'Level', 'Line', 'Message', 'ModuleName', 'Runspace', 'Tags', 'TargetObject', 'Timestamp', 'Type', 'Username')

	[DscProperty()]
	[bool]$IncludeHeader = $true

	[DscProperty()]
	[string]$Logname

	[DscProperty()]
	[string]$TimeFormat = "yyyy-MM-dd HH:mm:ss.fff"

	[DscProperty()]
	[string]$Encoding = 'UTF8'

	[DscProperty()]
	[bool]$UTC

	[DscProperty()]
	[string]$LogRotatePath

	[DscProperty()]
	[string]$LogRetentionTime

	[DscProperty()]
	[string]$LogRotateFilter

	[DscProperty()]
	[bool]$LogRotateRecurse

	[DscProperty()]
	[string]$MutexName

	[DscProperty()]
	[bool]$JsonCompress

	[DscProperty()]
	[bool]$JsonString

	[DscProperty()]
	[bool]$JsonNoComma

	[DscProperty()]
	[string]$MoveOnFinal

	[DscProperty()]
	[string]$CopyOnFinal
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
		CsvDelimiter     = { -not $args[0] }
		FilePath         = { $false }
		FileType         = { -not $args[0] }
		Headers          = { -not $args[0] }
		IncludeHeader    = { $false }
		Logname          = { -not $args[0] }
		TimeFormat       = { -not $args[0] }
		Encoding         = { -not $args[0] }
		UTC              = { -not $args[0] }
		LogRotatePath    = { -not $args[0] }
		LogRetentionTime = { -not $args[0] }
		LogRotateFilter  = { -not $args[0] }
		LogRotateRecurse = { -not $args[0] }
		MutexName        = { -not $args[0] }
		JsonCompress     = { -not $args[0] }
		JsonString       = { -not $args[0] }
		JsonNoComma      = { -not $args[0] }
		MoveOnFinal      = { -not $args[0] }
		CopyOnFinal      = { -not $args[0] }
	}

	[void]Set() {
		$this.AssertConfig()

		# Apply Desired State
		$logHelper = [PsfLoggingHelper]::new($this, 'Logfile')
		$extHelper = [ExtendedConfigHelper]::New($this, 'SystemDefault', "PSFramework.Logging.Logfile.$($this.InstanceName)", $this.PropertyMap)

		if ($this.Ensure -eq 'Absent') {
			$extHelper.Clear()
			$logHelper.Clear()
			return
		}

		$extHelper.Set()
		$logHelper.Set()
	}

	[PSFrameworkLogfile]Get() {
		# Return current actual state

		$result = [PSFrameworkLogfile]::new()
		$result.InstanceName = $this.InstanceName
		$result.Ensure = 'Absent'

		$logHelper = [PsfLoggingHelper]::new($this, 'Logfile')
		$extHelper = [ExtendedConfigHelper]::New($this, 'SystemDefault', "PSFramework.Logging.Logfile.$($this.InstanceName)", $this.PropertyMap)

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

		$logHelper = [PsfLoggingHelper]::new($this, 'Logfile')
		$extHelper = [ExtendedConfigHelper]::New($this, 'SystemDefault', "PSFramework.Logging.Logfile.$($this.InstanceName)", $this.PropertyMap)

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
		return [PsfLoggingHelper]::new($this, 'Logfile')
	}
	[ExtendedConfigHelper]GetCfgHelper() {
		return [ExtendedConfigHelper]::New($this, 'SystemDefault', "PSFramework.Logging.Logfile.$($this.InstanceName)", $this.PropertyMap)
	}

	[void]AssertConfig() {
		if ($this.Ensure -eq 'Absent') { return }

		if (-not $this.FilePath) { throw "Missing Setting: FilePath!" }
	}
}