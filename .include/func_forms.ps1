<#
.SYNOPSIS
Functions using methods from System.Windows.Forms namespace
.EXAMPLE
. '.include\func_forms.ps1'
#>
[void] [System.Reflection.Assembly]::Load('System.Windows.Forms')
Function Get-FileName($InitialDirectory, $FileFilter) {
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $InitialDirectory
    $OpenFileDialog.Filter = ($FileFilter ??= 'All types| *.*')
    [void] $OpenFileDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{ TopMost = $true }))
    return $OpenFileDialog.FileName
}
Function Get-Folder($InitialDirectory) {
    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($InitialDirectory) { $FolderBrowserDialog.SelectedPath = Join-Path $InitialDirectory -ChildPath $null }
    [void] $FolderBrowserDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{ TopMost = $true }))
    return $FolderBrowserDialog.SelectedPath
}
