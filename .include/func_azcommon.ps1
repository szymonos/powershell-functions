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
function Get-AzKeyVaultLoginPass {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)][string]$VaultName,
        [Parameter(Mandatory = $true)][string]$SecretName,
        [switch]$PsCredential
    )
    $kvCred = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName |`
        Select-Object -Property @{Name = 'UserName'; Expression = { $_.Tags.login } } `
        , @{Name = 'Password'; Expression = { $_.SecretValueText } } `
        , @{Name = 'VaultName'; Expression = { $VaultName } }
    if($PsCredential) {
        $password = ConvertTo-SecureString -String  $kvCred.Password -AsPlainText -Force
        New-Object System.Management.Automation.PSCredential ($kvCred.UserName, $password)
    } else {
        $kvCred
    }
}
function Get-AzKeyVaultCredential {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)][string]$VaultName,
        [Parameter(Mandatory = $true)][string]$SecretName
    )
    $cred = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName | `
        Select-Object -Property @{Name = 'user'; Expression = { $_.Tags.login } } `
        , @{Name = 'pass'; Expression = { ConvertTo-SecureString -String $_.SecretValueText -AsPlainText -Force } }
    return New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $cred.user, $cred.pass
}

function Get-AzKeyVaultAllLogins {
    param (
        [Parameter(Mandatory = $true)][string]$VaultName,
        [Parameter(Mandatory = $false)]$ContentType
    )
    $ContentType ??= '*'
    Get-AzKeyVaultSecret -VaultName $VaultName |
    Where-Object { $_.ContentType -like $ContentType } |
    ForEach-Object {
        $pass = (Get-AzKeyVaultSecret -VaultName $VaultName -Name $_.Name).SecretValueText
        $_ | Add-Member -MemberType NoteProperty -Name 'Password' -Value $pass -PassThru
    } |
    Select-Object -Property Name, @{Name = 'Login'; Expression = { $_.Tags.login } }, Password
}
