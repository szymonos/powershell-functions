<#
.Synopsis
https://www.c-sharpcorner.com/article/sharepoint-online-automation-o365-sharepoint-online-how-to-upload-your-files-r/
https://gallery.technet.microsoft.com/PowerShell-Bulk-Upload-b9e9d600#content
Install-Module SharePointPnPPowerShellOnline -AllowClobber
Update-Module SharePointPnPPowerShellOnline
https://www.sharepointdiary.com/2017/03/sharepoint-online-download-all-files-from-document-library-using-powershell.html
Get-InstalledModule -Name SharePointPnPPowerShellOnline | Select-Object *
.Example
& 'C:\Source\Git\DevOps\Migration\PnPFilesDownload.ps1'
#>

#Set Parameters
$TenantSiteURL = 'https://abcdata.sharepoint.com'
$SiteRelativeURL = '/sites/SBS'
$LibraryName = 'Shared Documents' #Path in address bar, not the library Name
$rootDir = 'D:\Migration\Teams'

$DownloadPath = Join-Path -Path $rootDir -ChildPath (Split-Path $SiteRelativeURL -Leaf)
if (!(Test-Path -Path $DownloadPath)) {
    New-Item -ItemType Directory -Path $DownloadPath
}

#Connect to PNP Online as Virtual Drive "SPO:\"
Connect-PnPOnline -Url $TenantSiteURL -CreateDrive -UseWebLogin

#Change the Path and navigate to the source site
Set-Location -Path SPO:\$SiteRelativeURL

#Download Document Library to Local Drive
Copy-PnpItemProxy -Recurse -Force $LibraryName $DownloadPath

# Remove Forms folder used in Teams
Get-ChildItem -Path $DownloadPath -Filter 'Forms' -Directory -Recurse | Remove-Item -Recurse -Force

Disconnect-PnPOnline
