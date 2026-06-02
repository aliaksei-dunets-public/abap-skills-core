param(
    [string]$ObjectName = ""
)

$wshell = New-Object -ComObject wscript.shell

# Give focus to VS Code
if (-not $wshell.AppActivate("Visual Studio Code")) {
    Write-Error "VS Code window not found. Is it open?"
    exit 1
}

Start-Sleep -Milliseconds 800

# Ctrl+Shift+A = "ABAP: Open Object" in SAP ADT for VS Code
$wshell.SendKeys("^+A")
Start-Sleep -Milliseconds 800

# Type the object name
$wshell.SendKeys($ObjectName)
Start-Sleep -Milliseconds 1000

# Confirm
$wshell.SendKeys("{ENTER}")

Write-Host "Done. Check VS Code for the opened object."
