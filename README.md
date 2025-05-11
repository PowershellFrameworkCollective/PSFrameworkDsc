# PSFramework Desired State Configuration Resources

Welcome to the Github Project for PSFramework DSC Resources.
With this you can deploy PSFramework settings - notably configuration system settings - via DSC.

Supported Resources:

+ PSFrameworkConfig
+ PSFrameworkLogEventLog
+ PSFrameworkLogFile
+ PSFrameworkLogSql

## Settings

### Common

All resources share one mandatory setting:

> Ensure: Present | Absent

Whether the resource should exist or not.
All settings other than `Ensure` and the key identifier are optional when `Ensure` is set to `Absent`.

### PSFrameworkConfig

Defines individual configuration settings of the PSFramework [configuration system](https://psframework.org/documentation/documents/psframework/configuration.html).

+ FullName (Key)
+ ConfigScope
+ Value
+ ValueType

> FullName `<string>`

The FullName setting is the full name of the configuration setting you want to define.
It is not case sensitive.

> ConfigScope: SystemDefault | SystemMandatory

Whether the configuration setting is written to the `SystemDefault` or `SystemMandatory` scope.
By default, settings are written to `SystemDefault`.

> Value `<string>`

The value to provide as a configuration setting.
DSC does _not_ support `[object]` types as value, forcing us to ask for a string value, along with a second setting to define the actual type.

See `ValueType` for how to define a non-string.

> ValueType `<string>`

What kind of value is provided as `Value`.
Supported types:

+ NotSpecified
+ Bool
+ Int
+ UInt
+ Int16
+ Int32
+ Int64
+ UInt16
+ UInt32
+ UInt64
+ Double
+ String
+ TimeSpan
+ DateTime
+ ConsoleColor
+ BoolArray
+ IntArray
+ UIntArray
+ Int16Array
+ Int32Array
+ Int64Array
+ UInt16Array
+ UInt32Array
+ UInt64Array
+ DoubleArray
+ StringArray
+ TimeSpanArray
+ DateTimeArray
+ ConsoleColorArray
+ PsfConfig

There are some special configuration settings to consider:

+ Unspecified: Is considered a string.
+ Bool: Expects a `true` or `1` as value for $true, everything else is $false.
+ PsfConfig: Expects the exact same value as PSFramework would write to registry. This is the only option that allows specifying other, non-simple configuration datatypes.
+ *Array: All array types expect their non-array equivalent values, separated by either a `|` or a `þ`. Use `þ` if you want to use `|` as a literal part of a string.

### PSFramework Logging

The settings on all logging provider resources directly map to the parameter name on the respective logging provider.

> General Settings

All logging Resources share the same general settings:

+ InstanceName (Key) `string`
+ Enabled `bool`
+ IncludeModules `<string[]>`
+ ExcludeModules `<string[]>`
+ IncludeFunctions `<string[]>`
+ ExcludeFunctions `<string[]>`
+ IncludeTags `<string[]>`
+ ExcludeTags `<string[]>`
+ MinLevel `int`
+ MaxLevel `int`

The only required setting being the `InstanceName`.
The `Enabled` setting defaults to true.

> PSFrameworkLogEventLog

Define a system-wide logging configuration to send [logs to the Windows Eventlog](https://psframework.org/documentation/documents/psframework/logging/providers/eventlog.html).
See the provider reference for the settings the EventLog provider accepts.

The only two mandatory settings are `LogName` and `Source`.

Example Configurations:

```powershell
PSFrameworkLogEventLog EventLog {
    InstanceName = 'EventLog'
    Ensure       = 'Present'
    LogName      = 'Application'
    Source       = 'PSFramework'
    Category     = 666
}

PSFrameworkLogEventLog EventLogOld {
    InstanceName = 'EventLogOld'
    Ensure       = 'Absent'
}
```

> PSFrameworkLogFile

Define a system-wide logging configuration to send [logs to a logfile](https://psframework.org/documentation/documents/psframework/logging/providers/logfile.html).
See the provider reference for the settings the Logfile provider accepts.

The only mandatory setting is `FilePath`.

Example Configurations:

```powershell
PSFrameworkLogFile LogFileLog {
    InstanceName = 'LogFileLog'
    Ensure       = 'Present'
    FilePath     = 'C:\Temp\Logs\System-%date%-%processid%.log'
    ExcludeTags  = 'debug', 'note'
}

PSFrameworkLogFile LogFileLogOld {
    InstanceName = 'LogFileLogOld'
    Ensure       = 'Absent'
}
```

> PSFrameworkLogSql

Define a system-wide logging configuration to send [logs to a SQL Database Table](https://psframework.org/documentation/documents/psframework/logging/providers/sql.html).
See the provider reference for the settings the SQL provider accepts.

The four mandatory settings are `SqlServer`, `Database`, `Schema`, and `Table`.

Example Configurations:

```powershell
PSFrameworkLogSql SystemLog {
    InstanceName = 'SystemLog'
    Ensure       = 'Present'
    SqlServer    = 'DscSql1'
    Database     = 'MSSQL'
    Schema       = 'pso'
    Table        = 'PSFLog'
}
PSFrameworkLogSql LegacyLog {
    InstanceName = 'LegacyLog'
    Ensure       = 'Absent'
}
```
