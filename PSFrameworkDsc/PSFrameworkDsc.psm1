enum Ensure
{
	Absent
	Present
}

enum Scope
{
	MachineDefault
	MachineEnforced
}

<#
	This resource manages the file in a specific path.
	[DscResource()] indicates the class is a DSC resource
#>

[DscResource()]
class PSFramework
{
	#region DSC Properties
	<#
		This property is the fully qualified path to the file that is
		expected to be present or absent.

		The [DscProperty(Key)] attribute indicates the property is a
		key and its value uniquely identifies a resource instance.
		Defining this attribute also means the property is required
		and DSC will ensure a value is set before calling the resource.

		A DSC resource must define at least one key property.
    #>
	[DscProperty(Key)]
	[string]$FullName;
	
    <#
		This property indicates if the settings should be present or absent
		on the system. For present, the resource ensures the file pointed
		to by $Path exists. For absent, it ensures the file point to by
		$Path does not exist.

		The [DscProperty(Mandatory)] attribute indicates the property is
		required and DSC will guarantee it is set.

		If Mandatory is not specified or if it is defined as
		Mandatory=$false, the value is not guaranteed to be set when DSC
		calls the resource. This is appropriate for optional properties.
    #>
	[DscProperty(Mandatory)]
	[Ensure] $Ensure;
	
    <#
    	The scope it is set to.
		DSC can only access the machine wide settings.
    #>
	[DscProperty]
	[Scope] $Scope;
	
    <#
		The value to apply
		Is only mandatory when $Ensure is set to "Present"
    #>
	[DscProperty]
	[string] $Value;
	#endregion DSC Properties
	
	#region DSC Methods
	<#
		This method is equivalent of the Set-TargetResource script function.
		It sets the resource to the desired state.
    #>
	[void] Set()
	{
		if ($this.Ensure -eq 'Present')
		{
			if (-not $this.IsLegalType($this.Value))
			{
				throw "Invalid value type! $($this.Value.GetType().FullName) is not a supported type"
			}
			
			$path = $this.PathDefault
			if ($this.Scope -eq 'MachineEnforced') { $path = $this.PathEnforced }
			
			$name = $this.FullName.ToLower()
			#$svalue = $this.Serialize($this.Value)
			
			if (-not (Test-Path $path))
			{
				$null = New-Item $Path -Force
			}
			
			Set-ItemProperty -Path $path -Name $name -Value $this.Value -ErrorAction Stop
		}
		else
		{
			$path = $this.PathDefault
			if ($this.Scope -eq 'MachineEnforced') { $path = $this.PathEnforced }
			
			$name = $this.FullName.ToLower()
			
			if (Test-Path $path)
			{
				try { Remove-ItemProperty -Path $path -Name $name -Force -ErrorAction Stop }
				catch { }
			}
		}
	}
	
    <#
		This method is equivalent of the Test-TargetResource script function.
		It should return True or False, showing whether the resource
		is in a desired state.
    #>
	[bool] Test()
	{
		$test = $false
		
		if ($this.Ensure -eq 'Present')
		{
			if (-not $this.IsLegalType($this.Value))
			{
				return $false
			}
			
			$path = $this.PathDefault
			if ($this.Scope -eq 'MachineEnforced') { $path = $this.PathEnforced }
			
			$name = $this.FullName.ToLower()
			#$svalue = $this.Serialize($this.Value)
			
			if (-not (Test-Path $path))
			{
				return $false
			}
			
			try { $prop = Get-ItemPropertyValue -Path $path -Name $name -ErrorAction Stop }
			catch { return $false }
			
			return ($prop -eq $this.Value)
		}
		else
		{
			$path = $this.PathDefault
			if ($this.Scope -eq 'MachineEnforced') { $path = $this.PathEnforced }
			
			$name = $this.FullName.ToLower()
			
			if (Test-Path $path)
			{
				try
				{
					$null = Get-ItemProperty -Path $path -Name $name -ErrorAction Stop
					return $false
				}
				catch { }
			}
			
			return $true
		}
		
		return $test
	}
	
    <#
		This method is equivalent of the Get-TargetResource script function.
		The implementation should use the keys to find appropriate resources.
		This method returns an instance of this class with the updated key
		properties.
    #>
	[PSFramework] Get()
	{
		if ($this.Scope -eq 'MachineEnforced') { $path = $this.PathEnforced }
		
		$name = $this.FullName.ToLower()
		
		$itemDefault = Get-ItemPropertyValue -Path $this.PathDefault -Name $name -ErrorAction Ignore
		$itemEnforced = Get-ItemPropertyValue -Path $this.PathEnforced -Name $name -ErrorAction Ignore
		
		if ($itemEnforced)
		{
			$this.Value = $itemEnforced
			$this.Ensure = 'Present'
			$this.Scope = 'MachineEnforced'
		}
		elseif ($itemDefault)
		{
			$this.Value = $itemDefault
			$this.Ensure = 'Present'
			$this.Scope = 'MachineDefault'
		}
		else
		{
			$this.Ensure = 'Absent'
		}
		
		return $this
	}
	#endregion DSC Methods
	
	hidden [string]$PathDefault = "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default"
	hidden [string]$PathEnforced = "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Enforced"
	
	[bool] IsLegalType($Object)
	{
		$typeName = $Object.GetType().FullName
		
		if ($typeName -eq "System.Object[]")
		{
			foreach ($item in $Object)
			{
				if (-not ($this.IsLegalType($item))) { return $false }
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
	
	[string] Serialize($Object)
	{
		switch ($Object.GetType().FullName)
		{
			"System.Object[]"
			{
				$list = @()
				foreach ($item in $Object)
				{
					$list += $this.Serialize($item)
				}
				return "array:$($list -join "þþþ")"
			}
			"System.Boolean"
			{
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
			default { throw "$($Object.GetType().FullName) was not recognized as a legal type!"}
		}
		
		return "<illegal data>"
	}
	
	[object] DeSerialize([string]$Item)
	{
		$index = $Item.IndexOf(":")
		if ($index -lt 1) { throw "No type identifier found!" }
		$type = $Item.Substring(0, $index).ToLower()
		$content = $Item.Substring($index + 1)
		
		switch ($type)
		{
			"bool"
			{
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
			"array"
			{
				$list = @()
				foreach ($item in ($content -split "þþþ"))
				{
					$list += $this.Deserialize($item)
				}
				return $list
			}
			
			default { throw "Unknown type identifier" }
		}
		
		return $null
	}
}