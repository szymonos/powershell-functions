<#
O365\TeamsFileCount.ps1
#>

$teams = Get-ChildItem -Path 'D:\Migration\Teams' -Directory

$files = @()
foreach ($team in $teams) {
    Write-Output ''
    Write-Output $team.Name
    $channels = Get-ChildItem -Path $team.FullName -Directory
    foreach ($channel in $channels) {
        Write-Output $channel.Name
        $folders = Get-ChildItem -Path $channel.FullName -Directory -Recurse | Where-Object { $_.Name -ne 'Forms' }
        foreach ($folder in $folders) {
            #$folder = $folders[0]
            $files += Get-ChildItem -Path $folder.FullName -File |
                Select-Object -Property Name, Length, CreationTime, LastAccessTime, LastWriteTime |
                Add-Member -MemberType NoteProperty -Name 'Folder' -Value $folder.Name -PassThru |
                Add-Member -MemberType NoteProperty -Name 'Team' -Value $team.Name -PassThru |
                Add-Member -MemberType NoteProperty -Name 'Channel' -Value $channel.Name -PassThru
        }
    }
}

$files | Export-Csv -Path '.\.assets\config\enumerateTeamsFiles.csv' -NoTypeInformation -Encoding utf8

#$files | Get-Member
