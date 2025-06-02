# ps_prompt

Native powershell prompt, runs without any external dependencies. Heavily inspired by the fantastic "bash-prompt" made by pkazmier (https://github.com/pkazmier/bash-prompt).

- Color themes
- Two row prompt
- Shows time, length of last command, current user, current directory (w/ auto shortening), and git branch

## Installation

1. Place the prompt file in \(USER)\Documents\WindowsPowerShell\psh_prompt.ps1

2. Add the following line to your PowerShell_profile.ps1 (and VSCode_profile.ps1 if you have it)
```powershell
# Get the directory of the profile script
$profileDir = Split-Path -Parent $PROFILE

# Dot-source the prompt script from the same directory
. "$profileDir\psh_prompt.ps1"
```
