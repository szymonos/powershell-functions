<#
.SYNOPSIS
Create symbolic link to your repos in C:\Source
#>

# Symbolic link to your repos on C drive
Set-Location 'C:\'
New-Item -ItemType SymbolicLink -Name 'Source' -Target 'H:\Source\'

# Symbolic link to other repos in already created C:\Source
Set-Location 'C:\Source'
New-Item -ItemType SymbolicLink -Name 'Git' -Target 'C:\Users\user\OneDrive\Git\'
