<#
.tools/BenchCommand.ps1
.tools/BenchCommand.ps1 -i 1000
#>
[CmdletBinding()]
param (
    [Alias('i')][int]$Iterations = 10
)
. .include/func_pscommon.ps1

$cmd = { git status }

$results = [System.Collections.Generic.List[decimal]]::new()

for ($i = 0; $i -lt $Iterations; $i++) {
    $pct = $i / $Iterations
    Write-Progress -Activity 'Bench command' -Status ('Processing: {0:P0}' -f $pct) -PercentComplete ($pct * 100)
    $results.Add((Measure-Command { & $cmd }).TotalMilliseconds)
}

if ($IsCoreCLR) {
    $results | Measure-Object -AllStats | Select-Object -Property Count `
        , @{Name = 'TimeStamp'; Expression = { (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } } `
        , @{Name = 'Average'; Expression = { Format-Duration ([timespan]::FromMilliseconds($_.Average)) } } `
        , @{Name = 'Minimum'; Expression = { Format-Duration ([timespan]::FromMilliseconds($_.Minimum)) } } `
        , @{Name = 'Maximum'; Expression = { Format-Duration ([timespan]::FromMilliseconds($_.Maximum)) } } `
        , @{Name = 'CoeficientOfVariation'; Expression = { Format-Duration ([timespan]::FromMilliseconds($_.StandardDeviation / $_.Average)) } } `
        , @{Name = 'Command'; Expression = { $cmd.ToString().Trim() } }
} else {
    $results | Measure-Object -AllStats | Select-Object -Property Count `
        , @{Name = 'TimeStamp'; Expression = { (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') } } `
        , @{Name = 'Average'; Expression = { Format-Duration ([timespan]::FromMilliseconds($_.Average)) } } `
        , @{Name = 'Minimum'; Expression = { Format-Duration ([timespan]::FromMilliseconds($_.Minimum)) } } `
        , @{Name = 'Maximum'; Expression = { Format-Duration ([timespan]::FromMilliseconds($_.Maximum)) } } `
        , @{Name = 'Command'; Expression = { $cmd.ToString().Trim() } }
}
