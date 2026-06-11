<#
.SYNOPSIS
    Tests for scripts/open-abap.ps1.

.DESCRIPTION
    Validates the script's input contract and resilience without actually
    activating any window or sending keystrokes. Real ADT integration cannot
    be unit-tested -- those parts are exercised manually via Step 2.6 of the
    skill.

    These tests cover:
      1. Script parses cleanly (no syntax errors).
      2. Required parameters declared (Mandatory on -ObjectName).
      3. Optional delay parameters present with sensible defaults.
      4. Empty / whitespace input is rejected with a stable error message.
      5. Display-form input '(NS)NAME' is rejected with a stable error
         message and a hint to use slash form.
      6. Slash-form input passes the validation block (verified by replacing
         the COM call with a stub).
      7. Bare Z-name (no namespace) passes the validation block.
      8. Validation messages remain stable -- the SKILL.md documents these
         strings as failure indicators, so wording must not regress.

    Designed for the dependency-free Invoke-Tests.ps1 runner.
#>

$scriptDir = Split-Path -Parent $PSCommandPath
$scriptUnderTest = Join-Path -Path (Split-Path -Parent $scriptDir) -ChildPath 'open-abap.ps1'

if (-not (Test-Path -LiteralPath $scriptUnderTest)) {
    throw "Script under test not found at: $scriptUnderTest"
}

# Helper -- run the script with arbitrary args in a child PowerShell process
# and capture stdout + stderr. The script is invoked indirectly through a
# wrapper file because only that lets us shadow Set-Clipboard / Start-Sleep
# and the wscript.shell COM call without modifying the script itself.
function Invoke-Script {
    param(
        [string[]]$ScriptArgs = @(),
        [switch]$StubAutomation
    )

    $wrapperLines = @()
    $wrapperLines += '$ErrorActionPreference = ''Continue'''
    if ($StubAutomation) {
        # Build a stub wscript.shell-shaped object whose AppActivate returns
        # true and whose SendKeys is a no-op. We replace New-Object globally
        # for the wrapper scope so the script under test gets the stub.
        $wrapperLines += '$global:__StubLog = [System.Collections.ArrayList]::new()'
        $wrapperLines += 'function global:New-Object { param([Parameter(ValueFromRemainingArguments=$true)] $rest)'
        $wrapperLines += '    $argList = @($rest) -join '' '''
        $wrapperLines += '    if ($argList -match ''wscript\.shell'') {'
        $wrapperLines += '        $obj = [pscustomobject]@{ Tag = ''stub'' }'
        $wrapperLines += '        $obj | Add-Member -Name AppActivate -MemberType ScriptMethod -Value { param($t) [void]$global:__StubLog.Add("AppActivate:$t"); return $true } -Force'
        $wrapperLines += '        $obj | Add-Member -Name SendKeys    -MemberType ScriptMethod -Value { param($k) [void]$global:__StubLog.Add("SendKeys:$k") } -Force'
        $wrapperLines += '        return $obj'
        $wrapperLines += '    }'
        $wrapperLines += '    Microsoft.PowerShell.Utility\New-Object @rest'
        $wrapperLines += '}'
        $wrapperLines += 'function global:Set-Clipboard { param($Value) [void]$global:__StubLog.Add("Clipboard:$Value") }'
        $wrapperLines += 'function global:Start-Sleep { param($Milliseconds, $Seconds) [void]$global:__StubLog.Add("Sleep:$Milliseconds") }'
    }
    $argString = ($ScriptArgs -join ' ')
    $wrapperLines += "try { & '$scriptUnderTest' $argString } catch { Write-Output ('CAUGHT: ' + `$_.Exception.Message) }"
    if ($StubAutomation) {
        # Surface the stub log on stdout so tests can assert on the keystrokes
        # the script tried to send. Each entry is emitted on its own line and
        # prefixed exactly as the stub recorded it (e.g. "SendKeys:^+A").
        $wrapperLines += 'foreach ($entry in $global:__StubLog) { Write-Output $entry }'
    }

    $tmp = [System.IO.Path]::GetTempFileName() + '.ps1'
    Set-Content -LiteralPath $tmp -Value ($wrapperLines -join "`r`n") -Encoding ASCII
    try {
        $stdout = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tmp 2>&1 |
                  ForEach-Object { $_.ToString() } |
                  Out-String
        return [pscustomobject]@{
            Output   = $stdout
            ExitCode = $LASTEXITCODE
        }
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

Test 'script parses without syntax errors' {
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $scriptUnderTest, [ref]$null, [ref]$errors) | Out-Null
    Assert-Equal 0 $errors.Count "parser reported $($errors.Count) error(s)"
}

Test 'parameter -ObjectName is declared Mandatory' {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $scriptUnderTest, [ref]$null, [ref]$null)
    $param = $ast.ParamBlock.Parameters |
        Where-Object { $_.Name.VariablePath.UserPath -eq 'ObjectName' }
    Assert-True ($null -ne $param) 'ObjectName parameter not found'

    $hasMandatory = $false
    foreach ($attr in $param.Attributes) {
        if ($attr.TypeName.FullName -eq 'Parameter') {
            foreach ($na in $attr.NamedArguments) {
                if ($na.ArgumentName -eq 'Mandatory') { $hasMandatory = $true }
            }
        }
    }
    Assert-True $hasMandatory '-ObjectName is missing Mandatory = $true'
}

Test 'optional delay parameters declared with int defaults' {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $scriptUnderTest, [ref]$null, [ref]$null)
    foreach ($name in @('InitialDelayMs', 'DialogDelayMs', 'PasteDelayMs')) {
        $param = $ast.ParamBlock.Parameters |
            Where-Object { $_.Name.VariablePath.UserPath -eq $name }
        Assert-True ($null -ne $param) "missing parameter: $name"
        Assert-True ($null -ne $param.DefaultValue) "$name has no default value"
    }
}

Test 'whitespace-only -ObjectName throws with stable message' {
    $r = Invoke-Script -ScriptArgs @('-ObjectName "   "')
    Assert-Match 'ObjectName is required and must not be empty' $r.Output `
        'expected stable rejection message for whitespace input'
}

Test 'display-form (NS)NAME is rejected with slash-form hint' {
    $r = Invoke-Script -ScriptArgs @('-ObjectName "(NS)CL_FOO"')
    Assert-Match 'must be in slash form' $r.Output `
        'expected hint pointing to slash form'
    Assert-Match 'display form' $r.Output `
        'expected explicit mention of display form'
}

Test 'rejection messages do not leak project-specific identifiers' {
    # The skill is project-agnostic; error messages must not embed real
    # namespaces, system IDs, or class prefixes from any specific project.
    $r = Invoke-Script -ScriptArgs @('-ObjectName "(REAL)CL_FOO"')
    Assert-NotMatch 'HEC4|SPC_DB|UPLOADER|ZCL_DAB|ISD_001' $r.Output `
        'project-specific identifiers must never leak into error messages'
}

Test 'slash-form /NS/NAME passes validation (with stubbed automation)' {
    $r = Invoke-Script -ScriptArgs @('-ObjectName "/NS/CL_FOO"') -StubAutomation
    Assert-Match 'Sent open-object command' $r.Output `
        'expected success log line after successful validation'
    Assert-NotMatch 'must be in slash form' $r.Output `
        'slash-form input must not be rejected'
    Assert-NotMatch 'is required and must not be empty' $r.Output `
        'slash-form input must not be flagged as empty'
}

Test 'bare Z-name without namespace passes validation' {
    $r = Invoke-Script -ScriptArgs @('-ObjectName "Z_MY_PROG"') -StubAutomation
    Assert-NotMatch 'must be in slash form' $r.Output `
        'bare Z-names are valid input and must not be rejected'
    Assert-Match 'Sent open-object command' $r.Output `
        'expected success log line after successful validation'
}

Test 'success log line includes the object name verbatim' {
    $name = '/NS/R_TESTOBJ_42'
    $r = Invoke-Script -ScriptArgs @("-ObjectName `"$name`"") -StubAutomation
    Assert-Match ([regex]::Escape($name)) $r.Output `
        'success log must include the requested object name'
}

Test 'output warns about integrated-terminal focus issue' {
    # SKILL.md "Known issues" relies on this warning being printed so the
    # caller (or the user reading stdout) understands why nothing happened
    # when the script was invoked from a VS Code integrated terminal.
    $r = Invoke-Script -ScriptArgs @('-ObjectName "/NS/CL_FOO"') -StubAutomation
    Assert-Match 'integrated terminal' $r.Output `
        'expected warning about VS Code integrated-terminal focus issue'
}

Test 'sends Escape keystrokes before the open-object chord' {
    # The Escape pre-keystrokes dismiss transient overlays (terminal
    # completion popups, hover cards) that would otherwise eat Ctrl+Shift+A.
    # If this contract changes, SKILL.md "Known issues" needs to be updated
    # in lockstep.
    $r = Invoke-Script -ScriptArgs @('-ObjectName "/NS/CL_FOO"') -StubAutomation
    Assert-Match 'SendKeys:\{ESC\}' $r.Output `
        'expected Escape keystroke to be sent at least once before the chord'
    Assert-Match 'SendKeys:\^\+A' $r.Output `
        'expected Ctrl+Shift+A chord to be sent after Escape'
}
