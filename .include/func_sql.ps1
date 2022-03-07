<#
. '.\.include\func_sql.ps1'
#>

# Assemblies required for Azure Active Directory Authentication
$verSqlClient = '2.0.1'
$verSqlSNI = '2.1.1'
$verIdentity = '4.35.1'
$nugetPackages = 'C:\Program Files\PackageManagement\NuGet\Packages'
$sqlClient = "$nugetPackages\Microsoft.Data.SqlClient.$verSqlClient\runtimes\win\lib\netcoreapp2.1\Microsoft.Data.SqlClient.dll"
$sqlSNI = "$nugetPackages\Microsoft.Data.SqlClient.SNI.runtime.$verSqlSNI\runtimes\win-x64\native\Microsoft.Data.SqlClient.SNI.dll"
$identityClient = "$nugetPackages\Microsoft.Identity.Client.$verIdentity\lib\netcoreapp2.1\Microsoft.Identity.Client.dll"
try {
    Add-Type -AssemblyName System.Data
    Add-Type -Path $sqlClient -ReferencedAssemblies $sqlSNI
    Add-Type -Path $identityClient
} catch {
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
        [Alias('s')][Parameter(Mandatory = $true)]
        [string]$ServerInstance,

        [Alias('d')][Parameter(Mandatory = $false)]
        [string]$Database = 'master',

        [Alias('c')][Parameter(Mandatory = $true, ParameterSetName = 'PsCred')]
        [pscredential]$Credential,

        [Alias('u')][Parameter(Mandatory = $true, ParameterSetName = 'UserPass')]
        [string]$User,

        [Alias('p')][Parameter(Mandatory = $false, ParameterSetName = 'UserPass')]
        [securestring]$Password,

        [Alias('r')][Parameter(Mandatory = $false)]
        [switch]$ConnectReplica,

        [Alias('i')][Parameter(Mandatory = $false)]
        [switch]$Interactive
    )
    if ($Credential) {
        $User = $Credential.UserName
        $Password = $Credential.Password
    }
    $builder = New-Object -TypeName 'Microsoft.Data.SqlClient.SqlConnectionStringBuilder'
    $builder.Server = $ServerInstance
    $builder.Database = $Database
    $builder.User = $User
    if (!$Interactive) {
        $builder.Password = ConvertFrom-SecureString $Password -AsPlainText
    }
    # !for compatibility: builder replaces authentication to: ActiveDirectoryPassword
    # !                   which is not supported by sqlpackage as of 18.6
    $connString = $builder.ConnectionString
    if ($User | Select-String -Pattern '@') {
        if ($Interactive) {
            $connString += ';Authentication=Active Directory Interactive'
        } else {
            $connString += ';Authentication=Active Directory Password'
        }
        #$builder.Authentication = "Active Directory Password"
    }
    # !for compatibility: builder replaces ApplicationIntent to: Application Intent
    # !                   which is not supported by sqlpackage as of 18.6
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
        [securestring]$Password,

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
        [securestring]$Password
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
        } if ($ConnectReplica) {
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
        } catch {
            $retryCount++
            ('.' * $retryCount)
            if ($retryCount -ge 10) {
                Write-Warning 'Resuming database failed'
                $retry = $false
            }
        } finally {
            $SqlConnection.Close()
        }
    }
}
