<#
.SYNOPSIS
Sort list using bubble sort algorithm.
.EXAMPLE
scripts/bubble_sort.ps1
#>
function Invoke-BubbleSort ([array]$array) {
    $start = Get-Date
    # operate on object copy instead of reference
    $lst = $array.PSObject.Copy()
    $k = $lst.Count
    for ($i = 0; $i -lt ($k - 1); $i++) {
        for ($j = 0; $j -lt ($k - $i - 1); $j++) {
            if ($lst[$j] -gt $lst[$j + 1]) {
                $lst[$j], $lst[$j + 1] = $lst[$j + 1], $lst[$j]
            }
        }
    }
    [Console]::WriteLine("`e[92mElapsed time: $((Get-Date) - $start)`e[0m")
    return $lst
}

$arr = @(64, 34, 25, 12, 22, 11, 90)
Invoke-BubbleSort $arr
