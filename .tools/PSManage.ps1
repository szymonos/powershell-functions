<#
.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_ansi_terminals
.EXAMPLE
.tools/PSManage.ps1
#>
# *PS Configuration file
$PSHOME
# PowerShell profile files
$Profile.CurrentUserCurrentHost
$Profile.CurrentUserAllHosts
$Profile.AllUsersCurrentHost
$Profile.AllUsersAllHosts

# Update help
Update-Help

# Set PS culture permanently
Set-Culture -CultureInfo 'en-SE'

# custom default values for cmdlet parameters
$PSDefaultParameterValues = @{
    'Get-ChildItem:Force' = $True
}

# *PSStyle
$PSStyle
$PSStyle.FileInfo

# set experimental features
Get-ExperimentalFeature
Enable-ExperimentalFeature PSAnsiRenderingFileInfo
Enable-ExperimentalFeature PSNativeCommandArgumentPassing

# *PowerShell latest version
$rel = (Invoke-RestMethod 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest').tag_name.TrimStart('v'); $rel
[System.Net.WebClient]::new().DownloadFile("https://github.com/PowerShell/PowerShell/releases/download/v$rel/PowerShell-$rel-win-x64.msi", './pwsh.msi')

# *Install latest PowerShellGet module
Install-Module PowerShellGet -AllowClobber -Force

<# *PSReadLine module manage
.LINK
https://docs.microsoft.com/en-us/powershell/module/psreadline
.EXAMPLE
Install-Module PSReadLine -AllowPrerelease -Force
#>
Get-PSReadLineKeyHandler
(Get-PSReadLineKeyHandler).Where({ $_.Function -match 'history' })
# binds keys to key handler functions
Set-PSReadLineKeyHandler -Chord Tab -Function MenuComplete
# set-up predictive suggestions
Set-PSReadLineKeyHandler -Chord F2 -Function SwitchPredictionView
Set-PSReadLineKeyHandler -Chord Shift+Tab -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord Alt+j -Function NextHistory
Set-PSReadLineKeyHandler -Chord Alt+k -Function PreviousHistory

# *Az Predictor
Install-Module -Name Az.Tools.Predictor
# set importing module and PSReadLine PredictionSource for the module
Enable-AzPredictor -AllSession
# enable predictionsource in PSReadLine to use AzPredictor plugin
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
# confirm settings in the profile
Get-Content $Profile.CurrentUserCurrentHost

# *dotnet autocomplete.
# https://www.hanselman.com/blog/how-to-use-autocomplete-at-the-command-line-for-dotnet-git-winget-and-more
# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
# https://github.com/microsoft/winget-cli/blob/master/doc/Completion.md
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
