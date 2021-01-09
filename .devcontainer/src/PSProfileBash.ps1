function Prompt {
    $promptPath = if ($PWD.ToString() -eq $env:USERPROFILE) { '~' } else { Split-Path $PWD -Leaf }
    return "[$env:USERNAME@$env:COMPUTERNAME $promptPath]$ "
}
