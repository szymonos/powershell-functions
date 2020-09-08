<#
. '.\.include\func_sql.ps1'
#>

# Assemblies required for Azure Active Directory Authentication
try {
    Add-Type -AssemblyName System.Data
    # Add-Type -Path ('C:\Program Files\PackageManagement\NuGet\Packages\Microsoft.Data.SqlClient.2.0.0\runtimes\win\lib\netcoreapp2.1\Microsoft.Data.SqlClient.dll') -ReferencedAssemblies Microsoft.Data.SqlClient.SNI
    # Add-Type -Path ('C:\Program Files\PackageManagement\NuGet\Packages\Microsoft.Identity.Client.4.17.1\lib\netcoreapp2.1\Microsoft.Identity.Client.dll')
    Add-Type -Path ('C:\Program Files\PackageManagement\NuGet\Packages\Microsoft.Data.SqlClient.1.1.3\runtimes\win\lib\netcoreapp2.1\Microsoft.Data.SqlClient.dll')
    Add-Type -Path ('C:\Program Files\PackageManagement\NuGet\Packages\Microsoft.Identity.Client.3.0.9\lib\netcoreapp2.1\Microsoft.Identity.Client.dll')
}
catch {
    'Assembly already loaded'
}

<#
.SYNOPSIS
Returns database connection string.
.DESCRIPTION
Returns database connection string using provided server name and username/password or pscredential.
Optionally accepts database name and application intent
Automatically detects AAD authentication.
.OUTPUTS
System.String
#>
function Resolve-ConnString {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerInstance,

        [Parameter(Mandatory = $false)]
        [string]$Database = 'master',

        [Parameter(Mandatory = $true, ParameterSetName = 'PsCred')]
        [pscredential]$Credential,

        [Parameter(Mandatory = $true, ParameterSetName = 'UserPass')]
        [string]$User,

        [Parameter(Mandatory = $true, ParameterSetName = 'UserPass')]
        [string]$Password,

        [Parameter(Mandatory = $false)][switch]$ConnectReplica
    )
    if ($Credential) {
        $User = $Credential.GetNetworkCredential().UserName
        $Password = $Credential.GetNetworkCredential().Password
    }
    $builder = New-Object -TypeName 'Microsoft.Data.SqlClient.SqlConnectionStringBuilder'
    $builder.Server = $ServerInstance
    $builder.Database = $Database
    $builder.User = $User
    $builder.Password = $Password
    # !for compatibility: builder replaces authentication to: ActiveDirectoryPassword
    # !                   which is not supported by sqlpackage as of 18.5.1
    $connString = $builder.ConnectionString
    if ($User | Select-String -Pattern '@') {
        $connString += ';Authentication=Active Directory Password'
        #$builder.Authentication = "Active Directory Password"
    }
    # !for compatibility: builder replaces ApplicationIntent to: Application Intent
    # !                   which is not supported by sqlpackage as of 18.5.1
    if ($ConnectReplica) {
        $connString += ';ApplicationIntent=ReadOnly'
        #$builder.ApplicationIntent = 'ReadOnly'
    }
    return $connString
}

function Invoke-SqlQuery {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ConnString')]
        [string]$ConnectionString,

        [Parameter(Mandatory = $true, ParameterSetName = 'Enumerate')]
        [string]$ServerInstance,

        [Parameter(Mandatory = $false, ParameterSetName = 'Enumerate')]
        [string]$Database = 'master',

        [Parameter(Mandatory = $false, ParameterSetName = 'Enumerate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'PsCred')]
        [pscredential]$Credential,

        [Parameter(Mandatory = $false, ParameterSetName = 'Enumerate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UserPass')]
        [string]$User,

        [Parameter(Mandatory = $false, ParameterSetName = 'Enumerate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UserPass')]
        [string]$Password,

        [Parameter(ParameterSetName = 'Enumerate')]
        [switch]$ConnectReplica,

        [Parameter(Mandatory = $true)]
        [string]$Query
    )
    if ($ServerInstance) {
        $resParams = @{
            ServerInstance = $ServerInstance
            Database       = $Database
        }
        if ($Credential) {
            $resParams.Add('Credential', $Credential)
        } else {
            $resParams.Add('User', $User)
            $resParams.Add('Password', $Password)
        }
        if ($ConnectReplica) {
            $resParams.Add('ConnectReplica', $ConnectReplica)
        }
        $ConnectionString = Resolve-ConnString @resParams
    }
    $SqlConnection = New-Object Microsoft.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = $ConnectionString
    $SqlCommand = New-Object Microsoft.Data.SqlClient.SqlCommand($Query, $SqlConnection)
    $SqlConnection.Open()
    $DataSet = New-Object System.Data.DataSet
    $SqlDataAdapter = New-Object Microsoft.Data.SqlClient.SqlDataAdapter $SqlCommand
    $SqlDataAdapter.Fill($DataSet) | Out-Null
    $SqlConnection.Close()
    $DataSet.Tables.Rows
}

function Start-AzSqlDatabase {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ConnString')]
        [string]$ConnectionString,

        [Parameter(Mandatory = $true, ParameterSetName = 'Enumerate')]
        [string]$ServerInstance,

        [Parameter(Mandatory = $true, ParameterSetName = 'Enumerate')]
        [string]$Database,

        [Parameter(Mandatory = $false, ParameterSetName = 'Enumerate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'PsCred')]
        [pscredential]$Credential,

        [Parameter(Mandatory = $false, ParameterSetName = 'Enumerate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UserPass')]
        [string]$User,

        [Parameter(Mandatory = $false, ParameterSetName = 'Enumerate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'UserPass')]
        [string]$Password
    )
    if ($ServerInstance) {
        $resParams = @{
            ServerInstance = $ServerInstance
            Database       = $Database
        }
        if ($Credential) {
            $resParams.Add('Credential', $Credential)
        } else {
            $resParams.Add('User', $User)
            $resParams.Add('Password', $Password)
        }
        if ($ConnectReplica) {
            $resParams.Add('ConnectReplica', $ConnectReplica)
        }
        $ConnectionString = Resolve-ConnString @resParams
    }
    "Resuming database $($Database)"

    $SqlConnection = New-Object Microsoft.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = $ConnectionString
    $retry = $true
    $retryCount = 0
    while ($retry) {
        try {
            $SqlConnection.Open()
            'Database is online'
            $retry = $false
        }
        catch {
            $retryCount++
            ('.' * $retryCount)
            if ($retryCount -ge 10) {
                Write-Warning 'Resuming database failed'
                $retry = $false
            }
        }
        finally {
            $SqlConnection.Close()
        }
    }
}
