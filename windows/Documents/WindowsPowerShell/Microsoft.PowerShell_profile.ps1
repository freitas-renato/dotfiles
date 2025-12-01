Invoke-Expression (&starship init powershell)

function Reload-Environment {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

New-Alias -Name reload-env -Value Reload-Environment
