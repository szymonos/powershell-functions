function Prompt {
    $promptPath = if ($PWD.ToString() -eq $HOME) { '~' } else { Split-Path $PWD -Leaf }
    return "[$($env:USERNAME.ToLower())@$($env:COMPUTERNAME.ToLower()) $promptPath]$ "
}
