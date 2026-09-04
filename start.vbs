Option Explicit

Dim shell, powerShellPath, scriptPath, command, exitCode, delaySeconds

Set shell = CreateObject("WScript.Shell")

delaySeconds = 30
If WScript.Arguments.Count > 0 Then
    If IsNumeric(WScript.Arguments(0)) Then delaySeconds = CInt(WScript.Arguments(0))
End If
WScript.Sleep delaySeconds * 1000

powerShellPath = "powershell.exe"
scriptPath = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\spicetify.ps1"
command = powerShellPath & " -ExecutionPolicy Bypass -NoProfile -File """ & scriptPath & """"

On Error Resume Next
exitCode = shell.Run(command, 0, True)
    ' Use 1 to show the window normally
    ' Use 0 to hide it completely
    ' Use 2 to minimize it
    ' Use 3 to maximize it

If Err.Number <> 0 Then
    WScript.Echo "Error launching PowerShell script: " & Err.Description
    WScript.Quit 1
End If
If exitCode <> 0 Then
    WScript.Echo "PowerShell script returned error code: " & exitCode
    WScript.Quit exitCode
End If

Set shell = Nothing