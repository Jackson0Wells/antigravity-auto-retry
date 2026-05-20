param(
    [int]$IntervalMilliseconds = 0,
    [switch]$NoIde
)

$ErrorActionPreference = "SilentlyContinue"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$retryScript = Join-Path $scriptDir "auto-retry.ps1"
$configPath = Join-Path $scriptDir "config.json"
$config = $null

if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
    } catch {
        $config = $null
    }
}

if ($IntervalMilliseconds -le 0) {
    if ($config -and $config.intervalMilliseconds -and [int]$config.intervalMilliseconds -ge 100) {
        $IntervalMilliseconds = [int]$config.intervalMilliseconds
    } else {
        $IntervalMilliseconds = 500
    }
}

function Show-Notice {
    param([string]$Message)

    try {
        $shell = New-Object -ComObject WScript.Shell
        [void]$shell.Popup($Message, 8, "Antigravity Auto Retry", 48)
    } catch {
        Write-Host $Message
    }
}

function Resolve-ShortcutTarget {
    param([string]$ShortcutPath)

    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($ShortcutPath)
        if ($shortcut.TargetPath -and (Test-Path $shortcut.TargetPath)) {
            return $shortcut.TargetPath
        }
    } catch {
        return $null
    }

    return $null
}

function Find-AntigravityIde {
    if ($env:ANTIGRAVITY_IDE_PATH -and (Test-Path $env:ANTIGRAVITY_IDE_PATH)) {
        return $env:ANTIGRAVITY_IDE_PATH
    }

    if ($config -and $config.antigravityIdePath -and (Test-Path $config.antigravityIdePath)) {
        return $config.antigravityIdePath
    }

    $candidatePaths = New-Object System.Collections.Generic.List[string]

    $commonRoots = @(
        $env:LOCALAPPDATA,
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)}
    ) | Where-Object { $_ }

    foreach ($root in $commonRoots) {
        $candidatePaths.Add((Join-Path $root "Programs\Antigravity IDE\Antigravity IDE.exe"))
        $candidatePaths.Add((Join-Path $root "Programs\Antigravity\Antigravity IDE.exe"))
        $candidatePaths.Add((Join-Path $root "Antigravity IDE\Antigravity IDE.exe"))
        $candidatePaths.Add((Join-Path $root "Antigravity\Antigravity IDE.exe"))
    }

    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        $candidatePaths.Add((Join-Path $drive.Root "Apps\Antigravity IDE\Antigravity IDE.exe"))
        $candidatePaths.Add((Join-Path $drive.Root "Apps\Antigravity\Antigravity IDE.exe"))
    }

    foreach ($path in $candidatePaths) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }

    $command = Get-Command "Antigravity IDE.exe"
    if ($command -and $command.Source -and (Test-Path $command.Source)) {
        return $command.Source
    }

    $shortcutRoots = @(
        (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"),
        (Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs"),
        (Join-Path $env:USERPROFILE "Desktop"),
        (Join-Path $env:PUBLIC "Desktop")
    ) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($root in $shortcutRoots) {
        $shortcuts = Get-ChildItem -Path $root -Filter "*Antigravity*.lnk" -Recurse
        foreach ($shortcut in $shortcuts) {
            $target = Resolve-ShortcutTarget -ShortcutPath $shortcut.FullName
            if ($target -and (Split-Path -Leaf $target) -like "*Antigravity*.exe") {
                return $target
            }
        }
    }

    return $null
}

if (-not (Test-Path $retryScript)) {
    Show-Notice "auto-retry.ps1 was not found next to the launcher."
    exit 1
}

if (-not $NoIde) {
    $idePath = Find-AntigravityIde
    if ($idePath) {
        Start-Process -FilePath $idePath
    } else {
        $runningIde = Get-Process | Where-Object {
            $_.ProcessName -like "*Antigravity*" -or $_.MainWindowTitle -like "*Antigravity*"
        } | Select-Object -First 1

        if (-not $runningIde) {
            Show-Notice "Antigravity IDE was not found automatically. Start Antigravity manually, or set ANTIGRAVITY_IDE_PATH to the full path of Antigravity IDE.exe."
        }
    }
}

& $retryScript -IntervalMilliseconds $IntervalMilliseconds -ExitWhenIdeMissingSeconds 3
