Select-String -Path '*.ps1' -Pattern [0-9]+ | `
    Select-Object @{Name = 'Match'; Expression = { $_.Matches.Value } }, Filename, LineNumber

Get-ChildItem 'H:\Users\szymo\OneDrive\Git' -Filter '_terminal.ps1' -Recurse -File | ForEach-Object {
    #$_.FullName
    Select-String -Path $_.FullName -Pattern 'Test-Connection' | Select-Object -Unique -Property Path
}
