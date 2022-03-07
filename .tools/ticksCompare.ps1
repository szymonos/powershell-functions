<#
.SYNOPSIS
Compare performance of two scripts.
.PARAMETER Iterations
Number of iterations to run the comparison. Default is 10.
.EXAMPLE
& "$SWD/.tools/ticksCompare.ps1"
& "$SWD/.tools/ticksCompare.ps1" -i 5
#>
using namespace System.Collections.Generic

param (
    [Alias('i')][int]$Iterations = 10
)

$script1 = {
    pwsh -NoProfile -c exit
}
$script2 = {
    pwsh -c exit
}

$propWins = [ordered]@{Measure = 'Wins' ; Script1 = 0; Script2 = 0 }
$results = [List[PSObject]]::new()
for ($i = 1; $i -le $Iterations; $i++) {
    $m1 = Measure-Command { & $script1 }
    $m2 = Measure-Command { & $script2 }
    $prop = [ordered]@{
        RunNo       = $i;
        Script1     = $m1.Ticks;
        Script2     = $m2.Ticks;
        Script1Secs = $m1.TotalSeconds;
        Script2Secs = $m2.TotalSeconds;
        pctDiff     = ([math]::Round(($m2.Ticks / $m1.Ticks - 1) * 100, 0))
    }
    $results += [pscustomobject]$prop
    if ($m1 -lt $m2) {
        $propWins.Script1 += 1
    } else {
        $propWins.Script2 += 1
    }
    Write-Output "$i. Script1 vs Script2 - $($propWins.Script1) : $($propWins.Script2)"
}
# Write detailed results
$results | Format-Table -AutoSize -Property RunNo, Script1, Script2, @{Name = 'Diff'; Expression = { $_.pctDiff.ToString() + '%' }; Align = 'Right' }

# Write summary results
$summary = [List[PSObject]]::new()
$summary += [PSCustomObject]$propWins
$summary += [PSCustomObject][ordered]@{
    Measure = 'Ticks';
    Script1 = ($results | Measure-Object 'Script1' -Sum).Sum;
    Script2 = ($results | Measure-Object 'Script2' -Sum).Sum;
}
$summary += [PSCustomObject][ordered]@{
    Measure = 'Seconds';
    Script1 = [math]::Round(($results | Measure-Object 'Script1Secs' -Sum).Sum, 3);
    Script2 = [math]::Round(($results | Measure-Object 'Script2Secs' -Sum).Sum, 3);
}
$summary += [PSCustomObject][ordered]@{
    Measure = 'Average[s]';
    Script1 = [math]::Round($summary[2].Script1 / $Iterations, 3);
    Script2 = [math]::Round($summary[2].Script2 / $Iterations, 3);
}
# write comparison summary
$summary

# Write summary conclusion
Write-Output ''
if ($summary[1].Script1 -lt $summary[1].Script2) {
    $overalTicksDiff = ([math]::Round(($summary[1].Script2 / $summary[1].Script1), 3))
    "Script1 was `e[1m$overalTicksDiff`e[0m times faster than Script2"
} else {
    $overalTicksDiff = ([math]::Round(($summary[1].Script1 / $summary[1].Script2), 3))
    "Script2 was `e[1m$overalTicksDiff`e[0m times faster than Script1"
}
