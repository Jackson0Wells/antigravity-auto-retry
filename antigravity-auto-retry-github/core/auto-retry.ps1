param(
    [int]$IntervalMilliseconds = 500,
    [int]$IntervalSeconds = 0,
    [string]$SignalDir = "",
    [int]$CooldownSeconds = 2,
    [int]$MaxBackoffSeconds = 15,
    [int]$ExitWhenIdeMissingSeconds = 0,
    [switch]$Once,
    [switch]$DryRun
)

# Auto Retry for Antigravity IDE.
# This script uses Windows UI Automation InvokePattern. It does not move the
# mouse, type keys, or focus the chat panel.

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

if ($IntervalSeconds -gt 0) {
    $IntervalMilliseconds = [Math]::Max(100, $IntervalSeconds * 1000)
}

if ($SignalDir -eq "") {
    $SignalDir = $PSScriptRoot
}

$logFile = Join-Path $SignalDir "auto-retry.log"
$root = [System.Windows.Automation.AutomationElement]::RootElement
$children = [System.Windows.Automation.TreeScope]::Children
$descendants = [System.Windows.Automation.TreeScope]::Descendants
$buttonType = [System.Windows.Automation.ControlType]::Button
$windowType = [System.Windows.Automation.ControlType]::Window
$trueCondition = [System.Windows.Automation.Condition]::TrueCondition

$lastRetryTime = [DateTime]::MinValue
$currentBackoffSeconds = 0
$hasSeenIdeWindow = $false
$lastIdeSeenTime = [DateTime]::MinValue

function Write-AutoRetryLog {
    param([string]$Message)

    $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $Message
    Write-Host $line
    try {
        Add-Content -Path $logFile -Value $line -Encoding UTF8
    } catch {
        # Keep running even if logging fails.
    }
}

function Get-AntigravityWindows {
    $windowCondition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        $windowType
    )

    $windows = $root.FindAll($children, $windowCondition)
    $matches = @()

    foreach ($window in $windows) {
        try {
            $name = $window.Current.Name
            if ($name -like "*Antigravity*" -or $name -like "*gym_tracker*") {
                $matches += $window
            }
        } catch {
            # Skip stale UIA elements.
        }
    }

    return $matches
}

function Test-AgentErrorVisible {
    param([System.Windows.Automation.AutomationElement]$Window)

    try {
        $elements = $Window.FindAll($descendants, $trueCondition)
        foreach ($element in $elements) {
            try {
                $name = $element.Current.Name
                if ($name -like "*Agent terminated due to error*" -or
                    $name -like "*servers are experiencing high traffic*" -or
                    $name -like "*You can prompt the model to try again*") {
                    return $true
                }
            } catch {
                # Skip stale UIA elements.
            }
        }
    } catch {
        return $false
    }

    return $false
}

function Get-RetryButtons {
    param([System.Windows.Automation.AutomationElement]$Window)

    $buttonCondition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        $buttonType
    )

    $buttons = @()

    try {
        $found = $Window.FindAll($descendants, $buttonCondition)
        foreach ($button in $found) {
            try {
                $name = $button.Current.Name
                $rect = $button.Current.BoundingRectangle
                $enabled = $button.Current.IsEnabled
                if ($enabled -and $name -eq "Retry" -and $rect.Width -gt 0 -and $rect.Height -gt 0) {
                    $buttons += $button
                }
            } catch {
                # Skip stale UIA elements.
            }
        }
    } catch {
        # Ignore transient UIA failures.
    }

    return $buttons
}

function Invoke-RetryButton {
    param([System.Windows.Automation.AutomationElement]$Button)

    try {
        $patternObj = $null
        $hasInvoke = $Button.TryGetCurrentPattern(
            [System.Windows.Automation.InvokePattern]::Pattern,
            [ref]$patternObj
        )

        if ($hasInvoke -and $patternObj -ne $null) {
            if ($DryRun) {
                Write-AutoRetryLog "Dry run: would invoke Retry button."
                return $true
            }

            $patternObj.Invoke()
            return $true
        }

        Write-AutoRetryLog "Retry button found but it does not expose InvokePattern."
    } catch {
        Write-AutoRetryLog "Invoke failed: $($_.Exception.Message)"
    }

    return $false
}

function Try-Retry {
    $now = Get-Date
    $requiredDelay = [Math]::Max($CooldownSeconds, $currentBackoffSeconds)

    if (($now - $script:lastRetryTime).TotalSeconds -lt $requiredDelay) {
        return $false
    }

    $sawRetryButton = $false
    $windows = @(Get-AntigravityWindows)

    if ($windows.Count -gt 0) {
        $script:hasSeenIdeWindow = $true
        $script:lastIdeSeenTime = $now
    }

    foreach ($window in $windows) {
        $windowName = ""
        try { $windowName = $window.Current.Name } catch {}

        $retryButtons = Get-RetryButtons -Window $window
        if ($retryButtons.Count -eq 0) {
            continue
        }

        $sawRetryButton = $true

        foreach ($button in $retryButtons) {
            if (Invoke-RetryButton -Button $button) {
                $script:lastRetryTime = Get-Date
                $script:currentBackoffSeconds = 0
                Write-AutoRetryLog "Invoked Retry in '$windowName'."
                return $true
            }
        }
    }

    if (-not $sawRetryButton) {
        $script:currentBackoffSeconds = 0
        return $false
    }

    if ($currentBackoffSeconds -eq 0) {
        $script:currentBackoffSeconds = 1
    } else {
        $script:currentBackoffSeconds = [Math]::Min($MaxBackoffSeconds, $currentBackoffSeconds * 2)
    }

    return $false
}

Write-AutoRetryLog "Auto Retry started (checking every ${IntervalMilliseconds}ms)."
Write-AutoRetryLog "This script invokes the Retry button through UI Automation only."
Write-AutoRetryLog "No keyboard, mouse, or chat focus control is used."
Write-AutoRetryLog "Log file: $logFile"
Write-AutoRetryLog "Press Ctrl+C to stop."

while ($true) {
    try {
        [void](Try-Retry)
    } catch {
        Write-AutoRetryLog "Loop error: $($_.Exception.Message)"
    }

    if ($ExitWhenIdeMissingSeconds -gt 0 -and
        $hasSeenIdeWindow -and
        ((Get-Date) - $lastIdeSeenTime).TotalSeconds -ge $ExitWhenIdeMissingSeconds) {
        Write-AutoRetryLog "Antigravity IDE has been closed for ${ExitWhenIdeMissingSeconds}s. Exiting."
        break
    }

    if ($Once) {
        break
    }

    Start-Sleep -Milliseconds $IntervalMilliseconds
}
