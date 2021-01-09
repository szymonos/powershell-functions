function Connect-Subscription {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)][string]$Subscription
    )

    [bool]$isGUID = try {
        [System.Guid]::Parse($Subscription) | Out-Null
        $true
    }
    catch {
        $false
    }

    $ctx = (Get-AzContext).Subscription | Select-Object -Property Id, Name
    if ($isGUID) {
        if ($null -eq $ctx.Id) {
            (Connect-AzAccount -SubscriptionId $Subscription).Context.Subscription | Select-Object -Property Id, Name
        }
        elseif ($ctx.Id -ne $Subscription) {
            (Set-AzContext -SubscriptionId $Subscription).Subscription | Select-Object -Property Id, Name
        }
        else {
            $ctx
        }
    }
    else {
        if ($null -eq $ctx.Id) {
            (Connect-AzAccount -Subscription $Subscription).Context.Subscription | Select-Object -Property Id, Name
        }
        elseif ($ctx -ne $Subscription) {
            (Set-AzContext -Subscription $Subscription).Subscription | Select-Object -Property Id, Name
        }
        else {
            $ctx
        }
    }
}

function Get-KeyVaultSecret {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)][string]$VaultName,
        [Parameter(Mandatory = $true)][string]$Name
    )
    $retryCount = 0
    while ($true) {
        try {
            $kvCred = Get-AzKeyVaultSecret -VaultName $VaultName -Name $Name -ErrorAction Stop
            return $kvCred
            break
        }
        catch [System.Net.Sockets.SocketException] {
            $retryCount++
            Start-Sleep 2
            if ($retryCount -ge 10) {
                Write-Error "$($_.Exception.Message) ($VaultName)"
                break
            }
        }
        catch {
            Write-Error $_.Exception.Message
            break
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
function Get-AzKeyVaultSecretValue {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)][string]$VaultName,
        [Parameter(Mandatory = $true)][string]$Name
    )
    $kvSecret = (Get-KeyVaultSecret -VaultName $VaultName -Name $Name).SecretValue

    $ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($kvSecret)
    try {
        $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
    }
    return $secretValueText
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
