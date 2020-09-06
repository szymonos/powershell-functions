<#
.SYNOPSIS
Setup Python virtual environment in the project and much more...
.EXAMPLE
.\setup.ps1 -Venv            # *Setup python virtual environment
.\setup.ps1 -Upgrade         # *Upgrade installed python modules
.\setup.ps1 -SshKey          # *Generate key pairs for SSH
.\setup.ps1 -SetEnv          # *Set environment variables
.\setup.ps1 -GetEnv          # *Get environment variables
.\setup.ps1 -List            # *List installed modules
.\setup.ps1 -Activate        # *Activate virtual environment
.\setup.ps1 -Deactivate      # *Deactivate virtual environment
#>

param (
    [switch]$Venv,
    [switch]$Upgrade,
    [switch]$SshKey,
    [switch]$SetEnv,
    [switch]$GetEnv,
    [switch]$List,
    [switch]$Activate,
    [switch]$Deactivate
)

<# Root directory of the application. #>
$APP_DIR = 'app'

<# Project environment variables. #>
if ($SetEnv -or $GetEnv) {
    $envTable = [ordered]@{
        APP_ROOT  = 'app';
        AppSecret = 'value'; # !set value
    }
}

# calculate script variables
[array]$req_files = 'requirements.txt'
if ($APP_DIR) {
    $appReq = [IO.Path]::Combine($APP_DIR, $req_files[0])
    if (Test-Path $appReq) {
        $req_files += $appReq
    }
}
$venvPath = [IO.Path]::Combine($APP_DIR, '.venv')
$venvCreated = Test-Path $venvPath
$activeatePath = if ($IsWindows) { 'Scripts' } else { 'bin' }
$activateScript = [IO.Path]::Combine($venvPath, $activeatePath, 'Activate.ps1')
$initScript = [IO.Path]::Combine('.vscode', 'init.ps1')
$GITIGNORE = 'https://raw.githubusercontent.com/github/gitignore/master/Python.gitignore'
$REQ = @{
    NAME  = $req_files[0]
    VALUE = "autopep8`nipykernel`nnotebook`npycodestyle`npytest`npylint`nisort`nlazy-object-proxy`nparso`npypath-magic`n"
}

<# Activate virtual environment #>
if ($Activate -or $Upgrade -or $Venv) {
    if ($null -eq $env:VIRTUAL_ENV -and $venvCreated) {
        & $activateScript
    }
}

<# Deactivate virtual environment. #>
if ($Deactivate -and $env:VIRTUAL_ENV) {
    deactivate
}

<# Setup python virtual environment. #>
if ($Venv) {
    <# Create virtual environment. #>
    if ($null -eq $env:VIRTUAL_ENV) {
        "`e[96mSetting up Python environment.`e[0m"
        if (!$venvCreated) {
            python -m venv $venvPath
        }
        # activate virtual environment
        & $activateScript
    } else {
        "`e[96mVirtual environment already set.`e[0m"
    }
    <# Add files to the project. #>
    if (!(Test-Path '.gitignore')) {
        "`e[95madd Python.gitignore`e[0m"
        (New-Object System.Net.WebClient).DownloadFile($GITIGNORE, '.gitignore')
    }
    if (!(Test-Path $REQ.NAME)) {
        "`e[95madd requirements.txt with dev modules`e[0m"
        New-Item $REQ.NAME -Value $REQ.VALUE | Out-Null
    }
    if (!(Test-Path $initScript)) {
        "`e[95mcreate init.ps1 for virtual environment activation`e[0m"
        $initContent = ('$activatePath = if ($IsWindows) { ''Scripts'' } else { ''bin'' }' + "`n" +
            '$activateScript = [IO.Path]::Combine(''{0}'', ''.venv'', $activatePath, ''Activate.ps1'')' -f $APP_DIR +
            "`n" + 'if (Test-Path $activateScript) { & $activateScript }' + "`n")
        New-Item -Path $initScript -Value $initContent -Force | Out-Null
    }
    if ($IsWindows) {
        if (!(Test-Path 'C:\ProgramData\chocolatey\bin\func.exe')) {
            "`e[95minstall Azure Functions Core Tools`e[0m"
            choco install azure-functions-core-tools-3 --params "'/x64'" -y
        }
    } elseif ($IsLinux) {
        if (!(Test-Path '/usr/bin/func')) {
            "`e[95minstall Azure Functions Core Tools`e[0m"
            curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
            sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
            sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
            sudo apt-get update
            sudo apt-get install azure-functions-core-tools-3
        }
    }
}

<# Upgrade all modules. #>
if ($Upgrade -or $Venv) {
    "`e[95mupgrade pip`e[0m"
    python -m pip install --upgrade pip
    if (Test-Path $REQ.NAME) {
        "`e[95minstall project requirements`e[0m"
        foreach ($req in $req_files) {
            python -m pip install -U -r $req --use-feature=2020-resolver
        }
        # upgrade all other modules
        $req_modules = foreach ($req in $req_files) {
            Get-Content $req | ForEach-Object { ($_ -split ('=='))[0] }
        }
        $modules = (python -m pip list --format=json | ConvertFrom-Json).name | `
            Where-Object { $_ -notin $req_modules }
    } else {
        $modules = (python -m pip list --format=json | ConvertFrom-Json).name
    }
    if ($modules) {
        "`e[95mupgrade other modules`e[0m"
        $reqs_temp = 'reqs_temp.txt'
        Set-Content -Path $reqs_temp -Value $modules
        python -m pip install -U -r $reqs_temp --use-feature=2020-resolver
        Remove-Item $reqs_temp
    }
    # add project path in virtual environment
    if ($env:VIRTUAL_ENV -and 'pypath-magic' -in $req_modules) {
        pypath add ([IO.Path]::Combine($PWD, $APP_DIR)) 2>$null
    }
}

<# Generate key pairs for SSH authentication in remote repository. #>
if ($SshKey) {
    if ($IsLinux) {
        # create new authentication key pairs for SSH if not exist
        if (!(Test-Path '~/.ssh/id_rsa.pub')) {
            sh -c "ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ''"
        }
        "`e[95mCopy below key and add to the repos' ssh public keys:`e[0m"
        Get-Content '~/.ssh/id_rsa.pub'
    } elseif ($IsWindows) {
        "`e[96mYou don't need to crete key for SSH, use HTTPS.`e[0m`n"
    }
}

<# Set environment user variables used in the project. #>
if ($SetEnv) {
    # set environment targed depending on host system
    $target = if ($IsWindows) { 'User' } else { 'Process' }
    # set environment variables
    foreach ($key in $envTable.Keys) {
        [Environment]::SetEnvironmentVariable($key, $envTable.$key, $target)
    }
    # restart explorer to initialize environment variables
    if ($IsWindows) { taskkill.exe /F /IM explorer.exe; Start-Process explorer.exe }
}

<# Get environment user variables used in the project. #>
if ($GetEnv) {
    foreach ($key in $envTable.Keys) {
        [PSCustomObject]@{
            Variable = $key;
            Value    = [Environment]::GetEnvironmentVariable($key)
        }
    }
}

<# List installed modules. #>
if ($List) {
    $modules = python -m pip list --format=json | ConvertFrom-Json; $modules
    $pipPath = ((python -m pip -V) -split (' '))[3] -replace ('\\pip', '')
    "`n`e[96m{0} | ({1}) modules installed in '{2}'`e[0m" -f (python -V), $modules.Count, $pipPath
}
