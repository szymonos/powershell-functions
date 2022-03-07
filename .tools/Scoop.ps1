<#
.SYNOPSIS
A command-line installer for Windows
.LINK
https://scoop.sh/
#>

#* Install scoop.
# Install Scoop to a Custom Directory by changing
$env:SCOOP = "C:\Users\$env:USERNAME\scoop"
[Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')
# run the installer
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')

# install extras bucket
scoop bucket add extras
# see all community buckets
scoop bucket known
# search
scoop search terraform
# check for updated packages
scoop status
# update scoop and all currently installed packages
scoop update
scoop update *
# help
scoop help

# *Install packages.
scoop install terraform
scoop install terraform@0.13.4
# uninstall package
scoop uninstall terraform
# hold an app to disable updates
scoop hold terraform
scoop unhold terraform

# *List installed packages.
scoop list

# *Cleanup apps
scoop cleanup *

# *Uninstall scoop.
scoop uninstall scoop

# neofetch fix
Set-Content -Path "$env:SCOOP\apps\neofetch\current\neofetch.ps1" -Value @'
$gitDir = (Get-Item (Get-Command git).Source).Directory.Parent.FullName
$bashPath = Join-Path $gitDir 'bin' 'bash.exe'
& $bashPath $(Join-Path $psscriptroot 'neofetch') @args
'@
