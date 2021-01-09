<#
.Synopsis
https://www.c-sharpcorner.com/article/sharepoint-online-automation-o365-sharepoint-online-how-to-upload-your-files-r/
https://gallery.technet.microsoft.com/PowerShell-Bulk-Upload-b9e9d600#content
Install-Module SharePointPnPPowerShellOnline -AllowClobber
Update-Module SharePointPnPPowerShellOnline
https://www.sharepointdiary.com/2017/03/sharepoint-online-download-all-files-from-document-library-using-powershell.html
Get-InstalledModule -Name SharePointPnPPowerShellOnline | Select-Object *
.Example
& 'C:\Source\Git\DevOps\Migration\PnPFilesDownload2.ps1'
#>

#Set Parameters

$TenantSiteURL = 'https://contoso.sharepoint.com'
$SiteRelativeURL = '\sites\dynamicsdocs'
$rootDir = 'D:\Migration\SPOnline'
$libraries = 'PMDocsSC', 'PMDocsPM', 'PMDocsDeploy', 'ReferenceInstructions', 'Notatki analityczne', 'Odbiory produktw', 'Raporty', 'ReferenceDocsProducts', 'ReferenceTemplates', 'PMTrainings', 'PMTests', 'Zaoenia  zakres'
$DownloadPath = Join-Path -Path $rootDir -ChildPath 'dynamicsdocs'
if (!(Test-Path -Path $DownloadPath)) {
    New-Item -ItemType Directory -Path $DownloadPath
}

#Connect to PNP Online as Virtual Drive "SPO:\"
Connect-PnPOnline -Url $TenantSiteURL -CreateDrive -UseWebLogin

foreach ($LibraryName in $libraries) {
    Write-Output ('Downloading library: ' + $LibraryName)
    #Change the Path and navigate to the source site
    Set-Location -Path SPO:\$SiteRelativeURL

    #Download Document Library to Local Drive
    Copy-PnpItemProxy -Recurse -Force $LibraryName $DownloadPath
}

Disconnect-PnPOnline
