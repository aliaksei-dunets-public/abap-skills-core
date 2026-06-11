param(
    [Parameter(Mandatory = $true)]
    [string]$ObjectName,

    [int]$InitialDelayMs = 800,
    [int]$DialogDelayMs  = 800,
    [int]$PasteDelayMs   = 1000
)

# -----------------------------------------------------------------------------
# WARNING: Integrated-terminal focus issue
# -----------------------------------------------------------------------------
# When this script is launched from a *VS Code integrated terminal*, focus
# typically remains on the terminal pane after AppActivate returns. The
# Ctrl+Shift+A keystroke is then consumed by the terminal -- not by the editor's
# command palette -- and the "ABAP: Open Object" dialog never appears.
#
# Reliable invocation paths:
#   1. From an *external* PowerShell window (Windows Terminal / pwsh.exe).
#   2. From a tool that spawns a detached child process (e.g. Start-Process).
#
# When neither is possible (e.g. running unattended from an agent that owns the
# integrated terminal), the SKILL.md instructs the agent to ask the user to
# open the object manually instead of relying on this script.
# -----------------------------------------------------------------------------

# Validate input -- must be the slash-namespaced form (e.g. /NS/CL_FOO) or a bare
# Z-name. Reject empty, parenthesised display form, or whitespace-only values.
#
# Note on error reporting: under Windows PowerShell 5.1 invoked via `-File`,
# neither `exit N` nor `throw` reliably propagate a non-zero exit code to the
# parent process -- the host returns 0 in most cases. Callers should therefore
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

# Best-effort: dismiss any transient overlay (terminal completion popup, hover,
# etc.) by sending Escape twice. This does NOT move focus into the editor on
# its own -- if focus is still in a side pane (e.g. the integrated terminal),
# the next chord will be consumed by that pane. See the WARNING block above.
$wshell.SendKeys("{ESC}")
$wshell.SendKeys("{ESC}")
Start-Sleep -Milliseconds 150

# Ctrl+Shift+A = "ABAP: Open Object" in SAP ADT for VS Code
$wshell.SendKeys("^+A")
Start-Sleep -Milliseconds $DialogDelayMs

# Copy object name to clipboard and paste -- avoids keyboard layout issues with SendKeys
Set-Clipboard -Value $ObjectName
$wshell.SendKeys("^v")
Start-Sleep -Milliseconds $PasteDelayMs

# Confirm
$wshell.SendKeys("{ENTER}")

Write-Host "Sent open-object command for '$ObjectName'. Wait >= 5 s before re-checking the cache."
Write-Host "If nothing happened, you are likely running from a VS Code integrated terminal -- re-run from an external PowerShell window or ask the user to open the object manually."

