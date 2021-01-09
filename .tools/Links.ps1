<#
.SYNOPSIS
Create different types of links on Windows
.LINK
https://docs.microsoft.com/en-us/windows/win32/fileio/hard-links-and-junctions
https://docs.microsoft.com/en-us/windows/win32/fileio/creating-symbolic-links
#>

# *Symbolic links (files and folders).
# symbolic link to your repos on C drive
New-Item -ItemType SymbolicLink -Path 'C:/Source' -Target 'H:/Source'
# symbolic link to other repos in already created C:\Source
New-Item -ItemType SymbolicLink -Path 'C:/Source/Git' -Target 'C:/Users/user/OneDrive/Git'

# *Junctions (directories only)
New-Item -ItemType Junction -Path 'C:/Source' -Target 'H:/Source'
New-Item -ItemType Junction -Path 'C:/Source/Git' -Target 'C:/Users/user/OneDrive/Git'

# *Hard links (files only).
New-Item -ItemType HardLink 'C:/Users/user2/.ssh/config' -Target '~/.ssh/config'
