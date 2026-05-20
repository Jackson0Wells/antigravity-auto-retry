param(
    [switch]$InstallMode
)

$ErrorActionPreference = "SilentlyContinue"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir "config.json"
$launcherPath = Join-Path $scriptDir "launch_ide_and_retry.ps1"
$startLauncherPath = Join-Path $scriptDir "launch_ide_and_retry_hidden.vbs"

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
    
    $candidatePaths = New-Object System.Collections.Generic.List[string]
    $commonRoots = @($env:LOCALAPPDATA, $env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }

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

    return ""
}

function Load-Config {
    if (-not (Test-Path $configPath)) {
        return $null
    }
    try {
        return Get-Content $configPath -Raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Save-Config {
    param(
        [string]$IdePath,
        [int]$IntervalMilliseconds,
        [bool]$RunHidden
    )
    $config = [ordered]@{
        antigravityIdePath = $IdePath
        intervalMilliseconds = $IntervalMilliseconds
        runHidden = $RunHidden
    }
    $config | ConvertTo-Json | Set-Content -Path $configPath -Encoding UTF8
}

function New-Shortcut {
    param(
        [string]$ShortcutPath,
        [string]$TargetPath,
        [string]$IconPath
    )
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ShortcutPath)
    if ($TargetPath.EndsWith(".vbs") -or $TargetPath.EndsWith(".bat")) {
        $shortcut.TargetPath = $TargetPath
    } else {
        $shortcut.TargetPath = "wscript.exe"
        $shortcut.Arguments = "`"$TargetPath`""
    }
    $shortcut.WorkingDirectory = $scriptDir
    if ($IconPath) {
        $shortcut.IconLocation = $IconPath
    } else {
        $shortcut.IconLocation = "powershell.exe,0"
    }
    $shortcut.Save()
}

function Remove-UserShortcuts {
    param([string]$IdePath)

    if (-not $IdePath -or -not (Test-Path $IdePath)) {
        return
    }

    $shortcutRoots = @(
        (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"),
        (Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs"),
        (Join-Path $env:USERPROFILE "Desktop"),
        (Join-Path $env:PUBLIC "Desktop")
    ) | Where-Object { $_ -and (Test-Path $_) }

    $shell = New-Object -ComObject WScript.Shell
    foreach ($root in $shortcutRoots) {
        $shortcuts = Get-ChildItem -Path $root -Filter "*.lnk" -Recurse
        foreach ($shortcut in $shortcuts) {
            try {
                $sc = $shell.CreateShortcut($shortcut.FullName)
                if ($sc.TargetPath -and ($sc.TargetPath -match "launch_ide_and_retry")) {
                    $sc.TargetPath = $IdePath
                    $sc.Arguments = ""
                    $sc.IconLocation = "$IdePath,0"
                    $sc.Save()
                }
            } catch { }
        }
    }
}

$existingConfig = Load-Config
$initialPath = ""
$initialInterval = 500
$initialRunHidden = $true

if ($existingConfig) {
    if ($existingConfig.antigravityIdePath) {
        $initialPath = [string]$existingConfig.antigravityIdePath
    }
    if ($existingConfig.intervalMilliseconds) {
        $initialInterval = [Math]::Max(100, [int]$existingConfig.intervalMilliseconds)
    }
    if ($null -ne $existingConfig.runHidden) {
        $initialRunHidden = [bool]$existingConfig.runHidden
    }
}

if (-not $initialPath) {
    $initialPath = Find-AntigravityIde
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Antigravity Auto Retry Setup"
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.ClientSize = New-Object System.Drawing.Size(610, 260)

$title = New-Object System.Windows.Forms.Label
$title.Text = "Antigravity Auto Retry"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(16, 14)
$form.Controls.Add($title)

$pathLabel = New-Object System.Windows.Forms.Label
$pathLabel.Text = "Antigravity IDE.exe location"
$pathLabel.AutoSize = $true
$pathLabel.Location = New-Object System.Drawing.Point(18, 58)
$form.Controls.Add($pathLabel)

$pathBox = New-Object System.Windows.Forms.TextBox
$pathBox.Location = New-Object System.Drawing.Point(20, 80)
$pathBox.Size = New-Object System.Drawing.Size(455, 26)
$pathBox.Text = $initialPath
$form.Controls.Add($pathBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Location = New-Object System.Drawing.Point(486, 78)
$browseButton.Size = New-Object System.Drawing.Size(98, 30)
$form.Controls.Add($browseButton)

$intervalLabel = New-Object System.Windows.Forms.Label
$intervalLabel.Text = "Check interval"
$intervalLabel.AutoSize = $true
$intervalLabel.Location = New-Object System.Drawing.Point(18, 124)
$form.Controls.Add($intervalLabel)

$intervalInput = New-Object System.Windows.Forms.NumericUpDown
$intervalInput.Location = New-Object System.Drawing.Point(120, 120)
$intervalInput.Size = New-Object System.Drawing.Size(90, 26)
$intervalInput.Minimum = 100
$intervalInput.Maximum = 10000
$intervalInput.Increment = 100
$intervalInput.Value = $initialInterval
$form.Controls.Add($intervalInput)

$msLabel = New-Object System.Windows.Forms.Label
$msLabel.Text = "milliseconds"
$msLabel.AutoSize = $true
$msLabel.Location = New-Object System.Drawing.Point(220, 124)
$form.Controls.Add($msLabel)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(18, 160)
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$statusLabel.Text = "Tip: 500ms is responsive without being noisy."
$form.Controls.Add($statusLabel)

$runHiddenCheckbox = New-Object System.Windows.Forms.CheckBox
$runHiddenCheckbox.Text = "Hide PowerShell window when running"
$runHiddenCheckbox.AutoSize = $true
$runHiddenCheckbox.Location = New-Object System.Drawing.Point(20, 188)
$runHiddenCheckbox.Checked = $initialRunHidden
$form.Controls.Add($runHiddenCheckbox)

$uninstallButton = New-Object System.Windows.Forms.Button
$uninstallButton.Text = "Detach / Uninstall"
$uninstallButton.Location = New-Object System.Drawing.Point(20, 216)
$uninstallButton.Size = New-Object System.Drawing.Size(130, 32)
$form.Controls.Add($uninstallButton)

$saveStartButton = New-Object System.Windows.Forms.Button
$saveStartButton.Text = "Save and Start"
$saveStartButton.Location = New-Object System.Drawing.Point(408, 216)
$saveStartButton.Size = New-Object System.Drawing.Size(108, 32)
$form.Controls.Add($saveStartButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.Location = New-Object System.Drawing.Point(524, 216)
$cancelButton.Size = New-Object System.Drawing.Size(72, 32)
$form.Controls.Add($cancelButton)

$browseButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Antigravity IDE.exe|Antigravity IDE.exe|Executable files (*.exe)|*.exe|All files (*.*)|*.*"
    $dialog.Title = "Select Antigravity IDE.exe"
    if ($pathBox.Text -and (Test-Path $pathBox.Text)) {
        $dialog.InitialDirectory = Split-Path -Parent $pathBox.Text
    }

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $pathBox.Text = $dialog.FileName
    }
})

$saveAction = {
    $idePath = $pathBox.Text.Trim()
    if (-not $idePath -or -not (Test-Path $idePath)) {
        [System.Windows.Forms.MessageBox]::Show("Choose a valid Antigravity IDE.exe path.", "Antigravity Auto Retry", "OK", "Warning") | Out-Null
        return $false
    }

    Save-Config -IdePath $idePath -IntervalMilliseconds ([int]$intervalInput.Value) -RunHidden $runHiddenCheckbox.Checked
    $statusLabel.Text = "Saved config.json."
    return $true
}

$uninstallButton.Add_Click({
    $idePath = $pathBox.Text.Trim()
    Remove-UserShortcuts -IdePath $idePath
    [System.Windows.Forms.MessageBox]::Show("Shortcuts removed or reverted! Your original Antigravity IDE shortcut has been restored. You can now safely delete this folder.", "Uninstalled", "OK", "Information") | Out-Null
})

$saveButton.Add_Click({
    if (& $saveAction) {
        [System.Windows.Forms.MessageBox]::Show("Settings saved.", "Antigravity Auto Retry", "OK", "Information") | Out-Null
    }
})

$saveStartButton.Add_Click({
    if (& $saveAction) {
        $argsList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$launcherPath`"")
        $windowStyle = "Normal"
        if ($runHiddenCheckbox.Checked) {
            $windowStyle = "Hidden"
        }
        Start-Process powershell.exe -WindowStyle $windowStyle -ArgumentList $argsList
        $form.Close()
    }
})

$cancelButton.Add_Click({
    $form.Close()
})

[void]$form.ShowDialog()
