function Set-Ascii {
    param (
        [string]$String
    )
    filter repla { $_.Replace('ą', 'a') }
    filter replc { $_.Replace('ć', 'c') }
    filter reple { $_.Replace('ę', 'e') }
    filter repll { $_.Replace('ł', 'l') }
    filter repln { $_.Replace('ń', 'n') }
    filter replo { $_.Replace('ó', 'o') }
    filter repls { $_.Replace('ś', 's') }
    filter replx { $_.Replace('ź', 'z') }
    filter replz { $_.Replace('ż', 'z') }
    filter replaa { $_.Replace('Ą', 'A') }
    filter replcc { $_.Replace('Ć', 'C') }
    filter replee { $_.Replace('Ę', 'E') }
    filter replll { $_.Replace('Ł', 'L') }
    filter replnn { $_.Replace('Ń', 'N') }
    filter reploo { $_.Replace('Ó', 'O') }
    filter replss { $_.Replace('Ś', 'S') }
    filter replxx { $_.Replace('Ź', 'Z') }
    filter replzz { $_.Replace('Ż', 'Z') }
    $String |
    repla | replaa |
    replc | replcc |
    reple | replee |
    repll | replll |
    repln | replnn |
    replo | reploo |
    repls | replss |
    replx | replxx |
    replz | replzz
}
function Get-IISServicesNames {
    param (
        [Parameter(Mandatory = $true)][string]$HostName
    )
    $script = {
        $sites = Get-WebSite | Where-Object { $_.State -ne 'Stopped' }
        foreach ($site in $sites) {
            foreach ($bind in $site.bindings.collection) {
                [PSCustomObject]@{
                    Name     = $site.Name;
                    Bindings = $bind.BindingInformation -replace '(:$)', ''
                    Protocol = $bind.Protocol;
                    Path     = $site.physicalPath;
                }
            }
        }
    }
    Invoke-Command -ComputerName $HostName -Credential $credsadm -ScriptBlock $script | Select-Object -ExcludeProperty RunspaceId, PSComputerName
}

<#
.SYNOPSIS
Calculate the entropy (in bits) of the provided string
.DESCRIPTION
Based primarily upon discussion here, https://technet.microsoft.com/en-us/library/cc512609.aspx
this function will calculate the entropy of the provided string, returning an integer result
indicating bits of entropy. Numerous assumptions MUST be made in the calculation of this
number. This function takes the easiest approach, which you can also read as "lazy" at best
or misleading at worst.
We need to figure out the "size" of the space from which the symbols in the string are drawn - after
all the value we're calculating is not absolute in any way, it's relative to some max/min values. We
make the following assumptions in this function:
--if there is a lower case letter in the provided string, assume it's possible any lower case letter could have been used. Assume the same for upper, numeric, and special chars.
--by "special characters" we mean the following: ~`!@#$%^&*()_-+={}[]|\:;"'<,>.?/
--by "letters", we mean just the letters on a U.S. keyboard.
--no rules regarding which symbols can appear where, e.g. can't start with a number.
--no rules disallowing runs, e.g. sequential numbers, sequential characters, etc.
--no rules considering non-normal distribution of symbols, e.g. "e" just as likley to appear as "#"
The net impact of these assumptions is we are over-calculating the entropy so the best use of this
function is probably for comparison between strings, not as some arbiter of absolute entropy.
.PARAMETER s
The string for which to calculate entropy.
.EXAMPLE
Get-StringEntropy -s "JBSWY3DPEHPK3PXP"
.NOTES
FileName: Get-StringEntropy
Author: nelsondev1
#>

function Get-StringEntropy {
    [CmdletBinding()]
    Param(
        [String]$s
    )

    $specialChars = @"
~`!@#$%^&*()_-+={}[]|\:;"'<,>.?/
"@

    $symbolCount = 0 # running count of our symbol space

    if ($s -cmatch '[a-z]+') {
        $symbolCount += 26
        Write-Verbose "$s contains at least one lower case character. Symbol space now $symbolCount"
    }
    if ($s -cmatch '[A-Z]+') {
        $symbolCount += 26
        Write-Verbose "$s contains at least one upper case character. Symbol space now $symbolCount"
    }
    if ($s -cmatch '[0-9]+') {
        $symbolCount += 10
        Write-Verbose "$s contains at least one numeric character. Symbol space now $symbolCount"
    }

    # In the particular use, I found trying to regex/match...challenging. Instead, just going
    # to iterate and look for containment.
    $hasSpecialChars = $false
    foreach ($c in $specialChars.ToCharArray()) {
        if ($s.Contains($c)) {
            $hasSpecialChars = $true
        }
    }
    if ($hasSpecialChars) {
        $symbolCount += $specialChars.Length
        Write-Verbose "$s contains at least one special character. Symbol space now $symbolCount"
    }

    # in a batch mode, we might want to pre-calculate the possible values since log is slow-ish.
    # there wouldn't be many unique options (eg 26, 26+26, 26+10, 26+16, 26+26+10, etc.)
    # ...though in comparison to performing the above regex matches it may not be a big deal.
    # anyway...

    # Entropy-per-symbol is the base 2 log of the symbol space size
    $entroyPerSymbol = [Math]::Log($symbolCount) / [Math]::Log(2)
    Write-Verbose "Bits of entropy per symbol calculated to be $entroyPerSymbol"

    $passwordEntropy = $entroyPerSymbol * $s.Length

    Write-Verbose "Returning value of $passwordEntropy"
    return [PSCustomObject]@{ Password = $s; Entropy = [math]::Round($passwordEntropy, 0) }
}

function New-Password {
    # https://powersnippets.com/create-password/
    [cmdletbinding()]
    param (                            # Version 01.01.00, by iRon
        [Int]$Size = 8,
        [Char[]]$Complexity = 'ULNS',
        [Char[]]$Exclude
    )
    $AllTokens = @();
    $Chars = @();
    $TokenSets = @{
        UpperCase = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        LowerCase = [Char[]]'abcdefghijklmnopqrstuvwxyz'
        Numbers   = [Char[]]'0123456789'
        Symbols   = [Char[]]'!#%&*+-<>@^_|~'
    }
    $TokenSets.Keys | Where-Object { $Complexity -Contains $_[0] } | ForEach-Object {
        $TokenSet = $TokenSets.$_ | Where-Object { $Exclude -cNotContains $_ } | ForEach-Object { $_ }
        if ($_[0] -cle 'Z') {
            $Chars += $TokenSet | Get-Random
        }
        $AllTokens += $TokenSet
    }
    while ($Chars.Count -lt $Size) {
        $Chars += $AllTokens | Get-Random
    } -join ($Chars | Sort-Object { Get-Random })
}
