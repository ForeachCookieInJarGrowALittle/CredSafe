<#
.Synopsis
Creates a new CredentialSafe for future Use
.Description
Depending on whether you provide a filepath or a SQL-Database a Table or XML-file gets
created to store your credentials
.Parameter XMLPath
Path to where you want the CredentialSafe to be stored
.Parameter SQLConnectionInfo
Creates a table in the Database provided.
Options for providing the connection-information are:
ConnectionString:
e.g. "Server=localhost\SQLEXPRESS;Database=master;Trusted_Connection=True;"
ConnectionInfo:
Servername\InstanceName,Port:Database:TableName
You can omit the TableName, in which case a Table named CS_$env:\username will be created.
#>
function New-CredSafe {
    [CmdletBinding(DefaultParameterSetName = "XML")]
    Param(
        # Path where you wand the CredentialSafe to be stored
        [Parameter(Mandatory=$false,ParameterSetName = "XML")]
        [String]
        $XMLPath = "$($env:LOCALAPPDATA)\CredSafe.xml"
        ,
        # SQL-ConnectionInfo
        [Parameter(Mandatory,ParameterSetName = "SQL")]
        [SQLConnectionInfo]
        $SQLConnectionInfo
    )
    if ($PSCmdlet.ParameterSetName -eq "XML") {
        if (-not (Test-Path $XMLPath)) {
            [CredSafe]::New($XMLPath)
        } else {
            Throw "There is already a Credsafe stored in that location"
        }
    } elseif ($PSCmdlet.ParameterSetName -eq 'SQL') {
        try {
            [CredSafe]::New($SQLConnectionInfo)
        } catch {
            Throw 'Could not create Credsafe-Table'
        }
    }
    
}