<#
.Synopsis
https://www.c-sharpcorner.com/article/sharepoint-online-automation-o365-sharepoint-online-how-to-upload-your-files-r/
https://gallery.technet.microsoft.com/PowerShell-Bulk-Upload-b9e9d600#content
Install-Module SharePointPnPPowerShellOnline -AllowClobber
Update-Module SharePointPnPPowerShellOnline
https://www.sharepointdiary.com/2017/03/sharepoint-online-download-all-files-from-document-library-using-powershell.html
Get-InstalledModule -Name SharePointPnPPowerShellOnline | Select-Object *
.Example
& 'C:\Source\Git\DevOps\Migration\PnPFilesDownload_Teams.ps1'
#>

#Set Parameters

$libaries = 'Freigegebene Dokumente', 'SiteAssets'
#$libaries = 'Shared Documents', 'SiteAssets'

$tenantSiteURL = 'https://also.sharepoint.com'
#$libraryName = 'Shared Documents' #Path in address bar, not the library Name
$rootDir = 'D:\Migration\Teams\also'

#Connect to PNP Online as Virtual Drive "SPO:\"
Connect-PnPOnline -Url $tenantSiteURL -CreateDrive -UseWebLogin

$teamsNick = Import-Csv -Path '.\.assets\enum\enumerateTeams.csv' | Select-Object -ExpandProperty MailNickName
foreach ($team in $teamsNick) {
    $SiteRelativeURL = "\sites\$team"
    $DownloadPath = Join-Path -Path $rootDir -ChildPath $team
    if (!(Test-Path -Path $DownloadPath)) {
        New-Item -ItemType Directory -Path $DownloadPath | Select-Object -ExpandProperty FullName
    }
    #Change the Path and navigate to the source site
    Set-Location -Path SPO:\$SiteRelativeURL
    foreach ($libraryName in $libaries) {
    #Download Document Library to Local Drive
        Copy-PnpItemProxy -Recurse -Force $libraryName $DownloadPath
        # Remove Forms folder
        Get-ChildItem -Path $DownloadPath -Filter 'Forms' -Directory -Recurse | Remove-Item -Recurse -Force
        Get-ChildItem -Path "$DownloadPath\$libraryName" -File | Remove-Item -Force
    }
}

Disconnect-PnPOnline
