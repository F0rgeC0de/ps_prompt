
# Color definitions using ANSI escape sequences for cross-platform compatibility
$Esc = [char]27
$Colors = @{
    Normal      = "${Esc}[0m"
    Black       = "${Esc}[30m"
    Red         = "${Esc}[31m"
    Green       = "${Esc}[32m"
    Yellow      = "${Esc}[33m"
    Blue        = "${Esc}[34m"
    Magenta     = "${Esc}[35m"
    Cyan        = "${Esc}[36m"
    White       = "${Esc}[37m"
    BrightBlack = "${Esc}[90m"
    BrightWhite = "${Esc}[97m"
}

# Global variables to hold theme colors
$Global:ThemeColors = @{}

function Set-PSPromptTheme {
    param(
        [ValidateSet('Dark','Colorful','White','Blue','Green','Yellow','Red')]
        [string]$Theme = 'Colorful'
    )

    switch ($Theme) {
        'Dark' {
            $Global:ThemeColors = @{
                Token          = $Colors.BrightBlack
                Time           = $Colors.BrightBlack
                DurationSuccess= $Colors.BrightBlack
                DurationFail   = $Colors.Red
                UserRoot       = $Colors.Red
                UserNonRoot    = $Colors.BrightBlack
                Hostname       = $Colors.BrightBlack
                Path           = $Colors.BrightBlack
                GitBranch      = $Colors.BrightBlack
                Jobs           = $Colors.BrightBlack
                Input          = $Colors.Blue
            }
        }
        'Colorful' {
            $Global:ThemeColors = @{
                Token          = $Colors.BrightBlack
                Time           = $Colors.BrightWhite
                DurationSuccess= $Colors.Green
                DurationFail   = $Colors.Red
                UserRoot       = $Colors.Red
                UserNonRoot    = $Colors.Magenta
                Hostname       = $Colors.Yellow
                Path           = $Colors.Cyan
                GitBranch      = $Colors.Magenta
                Jobs           = $Colors.Red
                Input          = $Colors.Blue
            }
        }
        'White' {
            $Global:ThemeColors = @{
                Token          = $Colors.BrightBlack
                Time           = $Colors.BrightWhite
                DurationSuccess= $Colors.BrightWhite
                DurationFail   = $Colors.Red
                UserRoot       = $Colors.Red
                UserNonRoot    = $Colors.BrightWhite
                Hostname       = $Colors.BrightWhite
                Path           = $Colors.BrightWhite
                GitBranch      = $Colors.BrightWhite
                Jobs           = $Colors.BrightWhite
                Input          = $Colors.Blue
            }
        }
        'Blue' {
            $Global:ThemeColors = @{
                Token          = $Colors.Blue
                Time           = $Colors.Blue
                DurationSuccess= $Colors.Blue
                DurationFail   = $Colors.Yellow
                UserRoot       = $Colors.Yellow
                UserNonRoot    = $Colors.Blue
                Hostname       = $Colors.Blue
                Path           = $Colors.Blue
                GitBranch      = $Colors.Blue
                Jobs           = $Colors.Blue
                Input          = $Colors.Red
            }
        }
    }
}

# Variables to track command timing
$Global:PromptStartTime = $null
$Global:LastCommandDuration = $null
$Global:LastCommandExitCode = $null

# Hook to capture command start time and exit code
function Start-CommandTimer {
    $Global:PromptStartTime = Get-Date
}

function Stop-CommandTimer {
    if ($Global:PromptStartTime) {
        $duration = (Get-Date) - $Global:PromptStartTime
        $Global:LastCommandDuration = [math]::Round($duration.TotalSeconds)
    } else {
        $Global:LastCommandDuration = 0
    }
    $Global:LastCommandExitCode = $LASTEXITCODE
}

# Override the prompt function
function prompt {
    Stop-CommandTimer

    $tc = $Global:ThemeColors

    # Time in HH:mm format
    $timeStr = (Get-Date).ToString('HH:mm')

    # Duration string with color based on exit code
    if ($Global:LastCommandExitCode -eq 0) {
        $durationColor = $tc.DurationSuccess
    } else {
        $durationColor = $tc.DurationFail
    }
    $durationStr = "${durationColor}[${Global:LastCommandDuration}s]${tc.Token}"

    # User and host
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    $userColor = if ($isAdmin) { $tc.UserRoot } else { $tc.UserNonRoot }
    $userStr = "${userColor}${user}${tc.Token}"

    $hostName = $env:COMPUTERNAME
    $hostStr = "${tc.Hostname}${hostName}${tc.Token}"

    # Current directory trimmed to last 3 segments, with ~ for home
    $homedir = [Environment]::GetFolderPath("UserProfile")
    $pwdPath = (Get-Location).Path
    if ($pwdPath.StartsWith($homedir)) {
        $pwdPath = "~" + $pwdPath.Substring($homedir.Length)
    }
    $pathSegments = $pwdPath -split '[\\/]' | Where-Object { $_ -ne '' }
    if ($pathSegments.Count -gt 3) {
        $trimmedPath = "..." + ($pathSegments[-3..-1] -join '\')
    } else {
        $trimmedPath = $pwdPath
    }
    $pathStr = "${tc.Path}${trimmedPath}${tc.Token}"

    # Git branch detection (if in a git repo)
    $gitBranch = ''
    try {
        $gitStatus = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $gitStatus) {
            $gitBranch = "${tc.GitBranch}${gitStatus}${tc.Token}"
        }
    } catch {}

    # Jobs count (background jobs)
    $jobsCount = (Get-Job -State Running,Suspended -ErrorAction SilentlyContinue).Count
    $jobsStr = ''
    if ($jobsCount -gt 0) {
        $jobsStr = "${tc.Jobs}${jobsCount}${tc.Token}"
    }

    # Build prompt lines with Unicode characters using escape sequences
    $line1 = $tc.Token + "| "+ $tc.Time + $timeStr + " " + $durationStr + " " + $tc.Token + "<" + $userStr + "@" + $hostStr + "> [" + $pathStr + "]"
    if ($gitBranch) { $line1 += " (" + $gitBranch + ")" }
    if ($jobsStr) { $line1 += " <" + $jobsStr + ">" }
    $line2 = $tc.Token + "|-> " + $tc.Input

    # Start timer for next command
    Start-CommandTimer

    # Return prompt string with reset color at end
    return "$line1`n$line2$($Colors.Normal)"
}

# Initialize with default theme
Set-PSPromptTheme -Theme Colorful
Start-CommandTimer
