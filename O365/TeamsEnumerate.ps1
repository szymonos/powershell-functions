<#
Update-Module MicrosoftTeams
Install-Module MicrosoftTeams -AllowClobber
Uninstall-Module MicrosoftTeams
Get-Command -Module MicrosoftTeams
Import-Module MicrosoftTeams
Get-Help Add-TeamUser -Examples
Get-Help Add-TeamUser -Detailed
Get-Help New-TeamChannel -examples
Get-TeamHelp
#>
# Get all commands for module MicrosoftTeams

. 'functions\func_common.ps1'

Import-Module MicrosoftTeams

# Connect to Microsoft Teams
$account = (Connect-MicrosoftTeams).Account.Id

# Get Teams user belongs to
Get-Team -User $account | Select-Object -Property DisplayName, MailNickName, Visibility

# Enumerate teams
$teams = Get-Team -User $account
$teams | Export-Csv -Path '.\.assets\enum\enumerateTeams.csv' -NoTypeInformation -Encoding utf8
<#
$teams | Sort-Object -Property DisplayName | Format-Table -AutoSize -Property GroupId, DisplayName, Visibility, MailNickName
#>

# Enumerate teams channels
$teams = Import-Csv -Path '.\.assets\enum\enumerateTeams.csv'
<#
$selTeams = 'ExternalPlatformsC' ,'Accounting' ,'AUDYT' ,'Obszarbiznesowy-ProduktManagement'
$teams = $teams | Where-Object -Property MailNickName -in $selTeams
#>
$teamChannels = @()
foreach ($team in $teams) {
    Write-Output ($team.DisplayName)
    $teamChannels += Get-TeamChannel -GroupId $team.GroupId |
    Add-Member -MemberType NoteProperty -Name 'GroupId' -Value $team.GroupId -PassThru |
    Add-Member -MemberType NoteProperty -Name 'GroupName' -Value $team.DisplayName -PassThru
}
$teamChannels | Export-Csv -Path '.\.assets\enum\enumerateTeamsChannels.csv' -NoTypeInformation -Encoding utf8

# Enumerate teams members
$teams = Import-Csv -Path '.\.assets\enum\enumerateTeams.csv'
$teamMembers = foreach ($team in $teams) {
    Get-TeamUser -GroupId $team.GroupId |
    Add-Member -MemberType NoteProperty -Name 'GroupId' -Value $team.GroupId -PassThru |
    Add-Member -MemberType NoteProperty -Name 'GroupName' -Value $team.DisplayName -PassThru
}
$teamMembers | Export-Csv -Path '.\.assets\enum\enumerateTeamsMembers.csv' -NoTypeInformation -Encoding utf8
<#
$teamMembers | Where-Object { $_.Role -eq 'owner' } | Format-Table -AutoSize -Property GroupName, Name, Role
#>

# Disconnect from Microsoft Teams
Disconnect-MicrosoftTeams
