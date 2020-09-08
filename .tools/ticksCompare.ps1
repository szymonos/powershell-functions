<#
.SYNOPSIS
Compare performance of two scripts.
.PARAMETER Iterations
Number of iterations to run the comparison. Default is 10.
.EXAMPLE
.tools\ticksCompare.ps1
.tools\ticksCompare.ps1 -Iterations 5
#>

param (
    [int]$Iterations = 10
)

$script1 = {
    Get-ChildItem -Path "C:\Windows\WinSxS" -Recurse -Filter "*WmsUserAddinConfig*"
}
$script2 = {
    Get-ChildItem -Path "C:\Windows\WinSxS" -Recurse  | Where-Object {$_.Name -like "*WmsUserAddinConfig*"}
}

$propWins = [ordered]@{Measure = 'Wins' ; Script1 = 0; Script2 = 0 }
$results = @()
1..$Iterations | ForEach-Object {
    $m1 = Measure-Command { & $script1 }
    $m2 = Measure-Command { & $script2 }
    $prop = [ordered]@{
        RunNo       = $_;
        Script1     = $m1.Ticks;
        Script2     = $m2.Ticks;
        Script1Secs = $m1.TotalSeconds;
        Script2Secs = $m2.TotalSeconds;
        pctDiff     = ([math]::Round(($m2.Ticks/$m1.Ticks - 1) * 100, 0))
    }
    $results += [pscustomobject]$prop
    if ($m1 -lt $m2) {
        $propWins.Script1 += 1
    }
    else {
        $propWins.Script2 += 1
    }
    Write-Output ($_.ToString() + '. Script1 vs Script2 - ' + $propWins.Script1 + ':' + $propWins.Script2)
}
# Write detailed results
$results | Format-Table -AutoSize -Property RunNo, Script1, Script2, @{Name = 'Diff'; Expression = { $_.pctDiff.ToString() + '%' }; ; Align = "Right" }

# Write summary results
$summary = @()
$summary += [PSCustomObject]$propWins
$propTicks = [ordered]@{
    Measure = 'Ticks';
    Script1 = ($results | Measure-Object 'Script1' -Sum).Sum;
    Script2 = ($results | Measure-Object 'Script2' -Sum).Sum;
}
$summary += [PSCustomObject]$propTicks
$propSecs = [ordered]@{
    Measure = 'Seconds';
    Script1 = [math]::Round(($results | Measure-Object 'Script1Secs' -Sum).Sum, 3);
    Script2 = [math]::Round(($results | Measure-Object 'Script2Secs' -Sum).Sum, 3);
}
$summary += [PSCustomObject]$propSecs
Write-Output $summary

# Write summary conclusion
Write-Output ''
if ($propTicks.Script1 -lt $propTicks.Script2) {
    $overalTicksDiff = ([math]::Round(($propTicks.Script2/$propTicks.Script1 - 1) * 100, 0))
    Write-Output ('Script1 was faster by ' + $overalTicksDiff + '%')
} else {
    $overalTicksDiff = ([math]::Round(($propTicks.Script1/$propTicks.Script2 - 1) * 100, 0))
    Write-Output ('Script2 was faster by ' + $overalTicksDiff + '%')
}
