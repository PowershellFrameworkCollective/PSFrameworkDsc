[DscResource()]
class PSFrameworkLogSql {
	#region DSC Properties
	[DscProperty(Mandatory)]
    [Ensure]$Ensure

	[DscProperty(Key)]
    [string]$InstanceName

	[DscProperty()]
	[string]$SqlServer

	[DscProperty()]
	[string]$Database

	[DscProperty()]
	[string]$Schema

	[DscProperty()]
	[string]$Table

	[DscProperty()]
	[PSCredential]$Credential

	[DscProperty()]
	[string[]]$Headers

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

	[DscProperty(NotConfigurable)]
	[Reason[]] $Reasons # Reserved for Azure Guest Configuration
	#endregion DSC Properties

	hidden [hashtable] $PropertyMap = @{
		SqlServer = { $false }
		Database = { $false }
		Schema = { $false }
		Table = { $false }
		Credential = { $null -eq $args[0] }
		Headers = { $null -eq $args[0] }
	}

    [void]Set() {
		$this.AssertConfig()

        # Apply Desired State
		$logHelper = [PsfLoggingHelper]::new($this, 'Sql')
		$extHelper = [ExtendedConfigHelper]::New($this, 'SystemDefault', "PSFramework.Logging.Sql.$($this.InstanceName)", $this.PropertyMap)

		if ($this.Ensure -eq 'Absent') {
			$extHelper.Clear()
			$logHelper.Clear()
			return
		}

		$extHelper.Set()
		$logHelper.Set()
    }

    [PSFrameworkLogSql]Get() {
		# Return current actual state

		$result = [PSFrameworkLogSql]::new()
		$result.InstanceName = $this.InstanceName
		$result.Ensure = 'Absent'

		$logHelper = [PsfLoggingHelper]::new($this, 'Sql')
		$extHelper = [ExtendedConfigHelper]::New($this, 'SystemDefault', "PSFramework.Logging.Sql.$($this.InstanceName)", $this.PropertyMap)

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

		$logHelper = [PsfLoggingHelper]::new($this, 'Sql')
		$extHelper = [ExtendedConfigHelper]::New($this, 'SystemDefault', "PSFramework.Logging.Sql.$($this.InstanceName)", $this.PropertyMap)

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
		return [PsfLoggingHelper]::new($this, 'Sql')
	}
	[ExtendedConfigHelper]GetCfgHelper() {
		return [ExtendedConfigHelper]::New($this, 'SystemDefault', "PSFramework.Logging.Sql.$($this.InstanceName)", $this.PropertyMap)
	}

	[void]AssertConfig() {
		if ($this.Ensure -eq 'Absent') { return }

		if (-not $this.SqlServer) { throw "Missing Setting: SqlServer!" }
		if (-not $this.Database) { throw "Missing Setting: Database!" }
		if (-not $this.Schema) { throw "Missing Setting: Schema!" }
		if (-not $this.Table) { throw "Missing Setting: Table!" }
	}
}