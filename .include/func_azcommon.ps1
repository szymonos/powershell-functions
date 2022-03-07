function Connect-Subscription {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)][string]$Subscription
    )

    $ctx = (Get-AzContext).Subscription | Select-Object -Property Id, Name, TenantId

    $comparator = try {
        [System.Guid]::Parse($Subscription) | Out-Null
        $ctx.Id
    }
    catch {
        $ctx.Name
    }

    if ($null -eq $ctx.Id) {
        (Connect-AzAccount -SubscriptionId $Subscription).Context.Subscription | Select-Object -Property Id, Name, TenantId
    }
    elseif ($comparator -ne $Subscription) {
        (Set-AzContext -SubscriptionId $Subscription).Subscription | Select-Object -Property Id, Name, TenantId
    }
    else {
        $ctx
    }
}

<#
.SYNOPSIS
Try for 12 seconds to retrieve KeyVault secret if "No such host is known."
.EXAMPLE
#>
function Get-KeyVaultSecret ($VaultName, $Name, [switch]$AsPlainText) {
    $start = Get-Date
    while ($true) {
        try {
            $kvCred = Get-AzKeyVaultSecret @psBoundParameters -ErrorAction Stop
            return $kvCred
            break
        }
        catch {
            if ($_.Exception.SocketErrorCode -eq 'HostNotFound') {
                if (((Get-Date) - $start).Seconds -gt 20) {
                    Write-Error "$($_.Exception.Message) ($VaultName)"
                    break
                }
                Start-Sleep 2
            }
            else {
                Write-Error $_.Exception.Message
                break
            }
        }
    }
}

function Get-AzKeyVaultCredential {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)][string]$VaultName,
        [Parameter(Mandatory = $true)][string]$Name,
        [switch]$AsPlainText
    )
    $kvCred = Get-KeyVaultSecret -VaultName $VaultName -Name $Name
    if ($AsPlainText) {
        $ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($kvCred.SecretValue)
        try {
            $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
            $cred = [PSCustomObject]@{
                VaultName = $kvCred.VaultName
                UserName  = $kvCred.Tags.login
                Password  = $secretValueText
                Tags      = ($kvCred.Tags.Keys | ForEach-Object { $_, $kvCred.Tags.Item($_) -join (':') }) -join ('; ')
            }
        }
    }
    else {
        $cred = New-Object System.Management.Automation.PSCredential ($kvCred.Tags.login, $kvCred.SecretValue)
    }
    return $cred
}

function Get-AzKeyVaultAllLogins {
    param (
        [Parameter(Mandatory = $true)][string]$VaultName,
        [Parameter(Mandatory = $false)]$ContentType
    )
    $ContentType ??= '*'
    Get-AzKeyVaultSecret -VaultName $VaultName |
    ForEach-Object {
        $kvCred = Get-AzKeyVaultSecret -VaultName $VaultName -Name $_.Name
        $ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($kvCred.SecretValue)
        try {
            $pass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
        }
        $_ | Add-Member -MemberType NoteProperty -Name 'Password' -Value $pass -PassThru
    } |
    Select-Object -Property Name, @{Name = 'Login'; Expression = { $_.Tags.login } }, Password
}
