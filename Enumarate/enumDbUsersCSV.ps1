<#
.Synopsis
.Example
Enumarate\enumDbUsersCSV.ps1
#>

$ErrorActionPreference = 'Stop'

# Include functions
. '.\.include\func_sql.ps1'
. '.\.include\func_azcommon.ps1'

# SQL queries used in script
$qryLogins = [System.IO.File]::ReadAllText('.\.include\sql\sel_logins.sql')
$qryUsers = [System.IO.File]::ReadAllText('.\.include\sql\sel_principals.sql')
function Add-LoginVerification {
    param (
        $Users
    )
    foreach ($user in $Users) {
        $loginFound = $logins | Where-Object { $_.name -eq $user.name -and $user.authentication_type -eq 1 }
        if ($null -eq $loginFound) {
            $user | Add-Member -MemberType NoteProperty -Name 'HasLogin' -Value $false
        }
        else {
            $user | Add-Member -MemberType NoteProperty -Name 'HasLogin' -Value $true
        }
    }
}

Write-Output 'Getting list of subscriptions'
$subscriptions = Import-Csv -Path '.\.assets\config\Az\az_subscriptions.csv'

Write-Output 'Getting list of SQL servers'
$sqlServers = Import-Csv -Path '.\.assets\config\Az\az_sqlservers.csv'

# Get credentials
$cred = Get-Secret 'Az'

$db_users = @()
foreach ($sub in $subscriptions) {
    #$sub = $subscriptions[0]
    Connect-Subscription -Subscription $sub.Id | Out-Null
    Write-Output ("`n" + 'Subscription ' + $sub.Name)
    $subServers = $sqlServers | Where-Object { $_.SubscriptionId -eq $sub.Id }

    Write-Output 'Enumerating databases on server:'
    foreach ($srv in $subServers) {
        #$srv = $subServers[1]
        Write-Output (' - ' + $srv.ServerName)

        # Get list of logins on server
        $logins = Invoke-SqlQuery -ServerInstance $srv.FullyQualifiedDomainName -Credential $cred -Query $qryLogins

        # Get list of SQL databases
        $dbList = Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName | Select-Object -Property DatabaseName, Status

        foreach ($db in $dbList) {
            #$db = $dbList[10]
            Write-Output ('Processing database ' + $db.DatabaseName)
            if ($db.Status -eq 'Paused') {
                Start-AzSqlDatabase -ServerInstance $srv.FullyQualifiedDomainName -Database $db.DatabaseName -Credential $cred
            }
            try {
                $instanceUsers = Invoke-SqlQuery -ServerInstance $srv.FullyQualifiedDomainName -Database $db.DatabaseName -Credential $cred -Query $qryUsers | `
                    Where-Object { $_.type -eq 'S' -and $_.authentication_type -eq 1 } | `
                    Select-Object -Property principal_id, name, authentication_type
                Add-LoginVerification -Users $instanceUsers
                $usersToDrop = $instanceUsers | Where-Object -Property 'HasLogin' -eq $false
                #$usersToDrop | Format-Table -AutoSize
                foreach ($user in $usersToDrop.name) {
                    try {
                        $qryDropUser = "drop user [$user];"
                        Invoke-SqlQuery -ServerInstance $srv.FullyQualifiedDomainName -Database $db.DatabaseName -Credential $cred -Query $qryDropUser
                        Write-Output ($user + ' - user dropped')
                    }
                    catch {
                        $error[0].Exception
                    }
                }
                $users = Invoke-SqlQuery -ServerInstance $srv.FullyQualifiedDomainName -Database $db.DatabaseName -Credential $cred -Query $qryUsers | `
                    Where-Object { $_.type -notin ('A', 'R') }
            }
            catch {
                Write-Warning ($db + ' - cannot get list of users in database')
            }
            $db_users += $users | Select-Object -Property * `
                , @{ Name = 'DatabaseName'; Expression = { $db.DatabaseName } } `
                , @{ Name = 'ServerName'; Expression = { $srv.ServerName } } `
                , @{ Name = 'SubscriptionId'; Expression = { $sub.Id } } `
                , @{ Name = 'Subscription'; Expression = { $sub.Name } }
        }
    }
}

$db_users | Export-Csv -Path '.\.assets\config\Az\az_dbusers.csv' -NoTypeInformation -Encoding utf8
