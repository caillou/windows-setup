Invoke-Expression (&starship init powershell)

$global:abbrs = @{
    ag   = 'rg -S'
    g    = 'lazygit'
    gb   = 'git branch --sort=-committerdate'
    ggl  = 'git pull'
    ggp  = 'git push'
    e    = 'code'
    glog = "git log --pretty='format:%C(auto)%h %s %Cgreen@%al %Cred@%ar' --graph"
    j    = 'z'
}

# Expand on Space (editable before you run)
Set-PSReadLineKeyHandler -Key Spacebar -ScriptBlock {
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($line.Substring(0, $cursor) -match '^\s*(\S+)$' -and $abbrs.ContainsKey($matches[1])) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
            $cursor - $matches[1].Length, $matches[1].Length, $abbrs[$matches[1]])
    }
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert(' ')
}

# Expand on Enter, then run (ValidateAndAcceptLine keeps proper multi-line handling)
Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($line -match '^\s*(\S+)' -and $abbrs.ContainsKey($matches[1])) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $matches[1].Length, $abbrs[$matches[1]])
    }
    [Microsoft.PowerShell.PSConsoleReadLine]::ValidateAndAcceptLine()
}
