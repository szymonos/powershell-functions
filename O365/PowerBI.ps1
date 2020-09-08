Connect-PowerBIServiceAccount

$logpath = '.\.assets\config\enumeratePowerBI.csv'
$Workspaces = Get-PowerBIWorkspace -Scope Organization -All

$Reports = ForEach ($workspace in $Workspaces) {
    Write-Host $workspace.Name
    ForEach ($report in (Get-PowerBIReport -Scope Organization -WorkspaceId $workspace.Id)) {
        [pscustomobject]@{
            WorkspaceID     = $workspace.Id
            WorkspaceName   = $workspace.Name
            ReportID        = $report.Id
            ReportName      = $report.Name
            ReportURL       = $report.WebUrl
            ReportDatasetID = $report.DatasetId
        }
    }
}
$Reports | Export-Csv -Path $logpath -NoTypeInformation -Encoding utf8

Disconnect-PowerBIServiceAccount
