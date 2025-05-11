class ExtendedConfigHelper {
	# Matching Property-Names to conditional logic to remove from config
	[hashtable]$Properties
	[string]$BasePath
	[object]$Item
	[Scope]$Scope

	[ConfigHelper]$Helper

	ExtendedConfigHelper([object]$Item, [Scope]$Scope, [string]$BasePath, [hashtable]$Properties) {
		$this.Item = $item
		$this.Scope = $Scope
		$this.BasePath = $BasePath
		$this.Properties = $Properties

		$this.Helper = [ConfigHelper]::new($Scope)
	}

	[bool]Test() {
		$this.Helper.Load()
		foreach ($property in $this.Properties.Keys) {
			if (-not $this.Helper.Compare($this.Item.$property, "$($this.BasePath).$property", $this.Properties.$property)) { return $false }
		}
		
		return $true
	}

	[hashtable]Get() {
		$this.Helper.Load()
		$result = @{}

		foreach ($property in $this.Properties.Keys) {
			if ($this.Helper.Config.Keys -contains "$($this.BasePath).$property") {
				$result[$property] = $this.Helper.Config."$($this.BasePath).$property"
			}
		}

		return $result
	}

	[void]Set() {
		$this.Helper.Load()

		foreach ($property in $this.Properties.Keys) {
			$this.Helper.Apply("$($this.BasePath).$property", $this.Item.$property, $this.Properties.$property)
		}
	}

	[void]Clear() {
		$this.Helper.Load()

		foreach ($property in $this.Properties.Keys) {
			$this.Helper.Remove("$($this.BasePath).$property")
		}
	}
}