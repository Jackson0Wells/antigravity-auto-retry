Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
launcherPath = fso.BuildPath(scriptDir, "launch_ide_and_retry.ps1")
command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File " & Chr(34) & launcherPath & Chr(34)
shell.Run command, 1, False
