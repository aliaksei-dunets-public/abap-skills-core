param(
    [Parameter(Mandatory = $true)]
    [string]$ObjectName,

    [int]$InitialDelayMs = 800,
    [int]$DialogDelayMs  = 800,
    [int]$PasteDelayMs   = 1000
)

# Validate input â€” must be the slash-namespaced form (e.g. /NS/CL_FOO) or a bare
# Z-name. Reject empty, parenthesised display form, or whitespace-only values.
#
# Note on error reporting: under Windows PowerShell 5.1 invoked via `-File`,
# neither `exit N` nor `throw` reliably propagate a non-zero exit code to the
# parent process â€” the host returns 0 in most cases. Callers should therefore
# detect failures by inspecting the script's stderr / stdout output rather than
# relying on `$LASTEXITCODE`. We still use `throw` so that the failure surfaces
# as a terminating error visible in stderr with a clear message.
if ([string]::IsNullOrWhiteSpace($ObjectName)) {
    throw "ObjectName is required and must not be empty."
}
if ($ObjectName -match '[()]') {
    throw "ObjectName must be in slash form (e.g. /NS/CL_FOO), not display form '(NS)CL_FOO'."
}

$wshell = New-Object -ComObject wscript.shell

# Give focus to VS Code. AppActivate uses a substring match against the window title.
if (-not $wshell.AppActivate("Visual Studio Code")) {
    # Fallback: try the Insiders / Code-OSS variants
    $activated = $false
    foreach ($title in @("Code", "VSCode", "Visual Studio Code - Insiders")) {
        if ($wshell.AppActivate($title)) { $activated = $true; break }
    }
    if (-not $activated) {
        throw "VS Code window not found. Is it open and running with the ADT extension?"
    }
}

Start-Sleep -Milliseconds $InitialDelayMs

# Ctrl+Shift+A = "ABAP: Open Object" in SAP ADT for VS Code
$wshell.SendKeys("^+A")
Start-Sleep -Milliseconds $DialogDelayMs

# Copy object name to clipboard and paste â€” avoids keyboard layout issues with SendKeys
Set-Clipboard -Value $ObjectName
$wshell.SendKeys("^v")
Start-Sleep -Milliseconds $PasteDelayMs

# Confirm
$wshell.SendKeys("{ENTER}")

Write-Host "Sent open-object command for '$ObjectName'. Wait >= 5 s before re-checking the cache."

