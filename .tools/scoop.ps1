<#
.SYNOPSIS
A command-line installer for Windows
.LINK
https://scoop.sh/
#>

#* Install scoop.
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
# install extras bucket
scoop bucket add extras
# see all community buckets
scoop bucket known
# search
scoop search neofetch
# upgrade all currently installed packages
scoop upgrade *
# help
scoop help

# *Install packages.
scoop install neofetch
