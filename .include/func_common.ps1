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
function New-Password {
    # https://powersnippets.com/create-password/
    [CmdletBinding()]param (                            # Version 01.01.00, by iRon
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
        Symbols   = [Char[]]'!#$%&*+,-.:<>@^_|~'
    }
    $TokenSets.Keys | Where-Object { $Complexity -Contains $_[0] } | ForEach-Object {
        $TokenSet = $TokenSets.$_ | Where-Object { $Exclude -cNotContains $_ } | ForEach-Object { $_ }
        if ($_[0] -cle 'Z') {
            $Chars += $TokenSet | Get-Random
        }
        $AllTokens += $TokenSet
    }
    While ($Chars.Count -lt $Size) {
        $Chars += $AllTokens | Get-Random
    }
    -join ($Chars | Sort-Object { Get-Random })
}
