<#
.SYNOPSIS
.EXAMPLE
$cred = Get-Secret 'AdmHV'
#>

$VMName = 'Core2004'

Enter-PSSession -VMName $VMName -Credential $cred
Exit-PSSession

# Manage Hyper-V machine
Get-VM
Start-VM $VMName
Restart-VM -Name $VMName -Force
Stop-VM -Name $VMName -Force

# Copy directory into VM
$copyItem = 'C:\Source\Repos\GitHub\AzureDevopsDockerPipelineAgent'
$destDir = 'C:\'
$sessionTo = New-PSSession -VMName $VMName -Credential $cred
Invoke-Command -Session $sessionTo -ScriptBlock {
    if ($false -eq (Test-Path -Path $using:destDir)) { New-Item -ItemType Directory $using:destDir }
}
Copy-Item $copyItem -Destination $destDir -ToSession $sessionTo -Force -Recurse; $sessionTo | Remove-PSSession

# Read Application log on remote machine
Get-WinEvent -LogName Application -MaxEvents 20 | Sort-Object TimeCreated | Format-List

# Get logons
$xPath = "Event[System[EventID=4624]] and Event[EventData[Data[@Name='TargetDomainName'] != 'Window Manager']] and Event[EventData[Data[@Name='TargetDomainName'] != 'NT AUTHORITY']] and (Event[EventData[Data[@Name='LogonType'] = '2']] or Event[EventData[Data[@Name='LogonType'] = '11']])"
Get-WinEvent -LogName 'Security' -FilterXPath $xPath | Format-List *
